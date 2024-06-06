# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Github: git@shandongtlb/MI9-Nethunter-Project
do.devicecheck=1
do.modules=1
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=cepheus
device.name2=
device.name3=
device.name4=
device.name5=
device.name6=
supported.versions=13
supported.patchlevels=
'; } # end properties

# shell variables
block=boot;
is_slot_device=0;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;


## NetHunter additions

mount -o rw,remount -t auto /system;
test -e /dev/block/bootdevice/by-name/system || local slot=$(getprop ro.boot.slot_suffix 2>/dev/null);
ui_print $slot
mount -o rw,remount -t auto /dev/block/bootdevice/by-name/system$slot /system_root;
ui_print "patching";
mkdir -p /data/adb/service.d/;
rm -rf /data/adb/service.d/patch.sh;
cp $home/patch/patch.sh /data/adb/service.d/;
chmod 0755 /data/adb/service.d/patch.sh;
SYSTEM="/system";
SYSTEM_ROOT="/system_root";

setperm() {
	find "$3" -type d -exec chmod "$1" {} \;
	find "$3" -type f -exec chmod "$2" {} \;
}

install() {
	setperm "$2" "$3" "$home$1";
	if [ "$4" ]; then
	    # ui_print "$home$1  to  $(dirname "$4")/"
		cp -r "$home$1" "$(dirname "$4")/";
		return;
	fi;
	cp -r "$home$1" "$(dirname "$1")/";
}


[ -d $home/data/local ] && {
	install "/data/local" 0755 0644;
}

[ -d $home/ramdisk-patch ] && {
    ui_print "patching ramdisk"
	setperm "0755" "0750" "$home/ramdisk-patch";
        chown root:shell $home/ramdisk-patch/*;
    # ui_print "$home/ramdisk-patch/  to  $SYSTEM_ROOT/"
	cp -r $home/ramdisk-patch/* "$SYSTEM_ROOT/";
        chmod 666 $SYSTEM_ROOT/*.bin
}


insert_line $SYSTEM_ROOT/ueventd.rc "/dev/hidg" after "/dev/vndbinder.*root.*root" "# HID driver\n/dev/hidg* 0666 root root";

grep "Kali" $SYSTEM_ROOT/init.usb.configfs.rc > /dev/null
if [ $? -eq 0 ]; then
    ui_print "init.usb.configfs.rc have been patched, skipped!";
else
    ui_print "patching init.usb.configfs.rc";
    cat $home/tools/init.nethunter.rc >> $SYSTEM_ROOT/init.usb.configfs.rc 
fi

# disable android compatibility-matrix for SYSTEM V IPC

mount -o ro,remount -t auto /system;
## End NetHunter additions

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
# set_perm_recursive 0 0 755 644 $ramdisk/*;
# set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;



## AnyKernel install
dump_boot;

# begin ramdisk changes

if [ -d $ramdisk/.backup ]; then
  patch_cmdline "skip_override" "skip_override";
else
  patch_cmdline "skip_override" "";
fi;


# end ramdisk changes

write_boot;
## end install

