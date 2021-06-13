#!/usr/bin/expect -f

set packages [lindex $argv 0];

set timeout -1

spawn pacman -S "$packages" --noconfirm --needed
expect {
  "Enter a selection" {
    send -- "\r"
    exp_continue
  }
}
