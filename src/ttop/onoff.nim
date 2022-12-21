import osproc
import os
import strformat

# const timer = "*-*-* *:*:08"
const timer = "minutely"
const unit = "ttop"
const descr = "ttop service snapshot collector"

const options = {poUsePath, poEchoCmd}



proc createService(file: string, app: string) =
  if fileExists file:
    return
  echo "create ", file
  writeFile(file,
      &"""
[Unit]
Description={descr}

[Service]
ExecStart={app} -s

[Install]
WantedBy=ttop.timer
""")

proc createTimer(file: string, app: string) =
  if fileExists file:
    return
  echo "create ", file
  writeFile(file,
      &"""
[Unit]
Description={descr} timer

[Timer]
OnCalendar={timer}

[Install]
WantedBy=timers.target
""")

proc createConfig() =
  let dir = getConfigDir().joinPath("systemd", "user")
  if not dirExists dir:
    createDir dir

  let app = getAppFilename()
  createService(dir.joinPath(&"{unit}.service"), app)
  createTimer(dir.joinPath(&"{unit}.timer"), app)

proc deleteConfig() =
  let dir = getConfigDir().joinPath("systemd", "user")

  var file = dir.joinPath(&"{unit}.service")
  echo "delete ", file
  removeFile file
  file = dir.joinPath(&"{unit}.timer")
  echo "delete ", file
  removeFile file

proc cmd(cmd: string) =
  let (output, code) = execCmdEx(cmd, options = options)
  if output.len > 0:
    echo output
  if code != 0:
    quit code

proc onoff*(enable: bool) =
  if enable:
    createConfig()
    cmd &"systemctl --user start '{unit}.timer' '{unit}.service'"
    cmd "loginctl enable-linger"
  else:
    cmd &"systemctl --user stop '{unit}.timer' '{unit}.service'"
    deleteConfig()
    cmd "loginctl disable-linger"

