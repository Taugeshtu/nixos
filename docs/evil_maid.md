 potentially never going to be a concern, but is there possibly a threat vector where not a
 ┃ thief, but a malicious actor patches the kernel on the unencrypted volume that allows kiosk go do
 ┃ many more things?.. or like, even at the most basic level, keylogger in the kernel? And how can
 ┃ we possibly protect against that? Boot into tinycore linux that then SWAPS kernel in-place with
 ┃ the one off encrypted drive?..
 ┃
 ┃   Yes. Threat is very real. Security world call this Evil Maid attack.
 ┃
 ┃   If unencrypted partition or /boot has no integrity check, bad actor with physical access can
 ┃   patch kernel, initrd, or PAM script. When tau types LUKS passphrase to unlock Vault, evil
 ┃   kernel logs passphrase and stores it or sends over network.
 ┃   ──────
 ┃   ### Why TinyCore / kexec swap not solve problem alone
 ┃
 ┃   Grug call this "chicken and egg" problem:
 ┃
 ┃   • If unencrypted boot loader or TinyCore kernel is tampered with, evil kernel already owns
 ┃   machine before it reaches encrypted drive.
 ┃   • Evil kernel can fake the kexec, run hypervisor underneath, or log the unlock passphrase
 ┃   before handoff.
 ┃   • Trust must start from hardware.
 ┃   ──────
 ┃   ### Real ways to stop this
 ┃
 ┃   • Secure Boot + Custom Keys + UKI (Unified Kernel Image):
 ┃       • Put kernel, initrd, and kernel cmdline into single .efi binary.
 ┃       • Sign binary with tau's own private Secure Boot key (enrolled in UEFI).
 ┃       • Motherboard firmware refuses to boot modified kernel or bootloader.
 ┃   • dm-verity on System Partition:
 ┃       • Make unencrypted System volume read-only and backed by dm-verity hash tree.
 ┃       • Signed root hash lives inside the signed UKI.
 ┃       • If attacker flips single bit on unencrypted system disk, kernel refuses to read block
 ┃       and halts.
 ┃   • TPM2 Measured Boot:
 ┃       • TPM chip measures firmware, bootloader, kernel, and initrd into PCR registers during
 ┃       boot.
 ┃       • If attacker modifies any byte, PCR values change, alerting tau or locking hardware
 ┃       token.
 ┃   • Detached /boot on Keychain USB:
 ┃       • Keep /boot (kernel + initrd) on small physical USB flash drive in tau pocket.
 ┃       • Machine has zero boot files on internal drive when powered off. Attacker has nothing to
 ┃       patch.
