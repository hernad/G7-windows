
set GREENBOX_INSTALL_PATH=%1
set TASK_USER=%2
set TASK_PASSWORD=%3


SchTasks /Create /SC ONSTART /TN "sshd greenbox 22"  /ru %TASK_USER% /rp %TASK_PASSWORD% ^
    /TR "\"C:\Program Files\Git\bin\bash.exe\"  --login -i \"%GREENBOX_INSTALL_PATH%\sshd.sh\" 22"


echo windows xp UDP port 53
netsh firewall add portopening UDP 80 "DNS"

echo windows xp port 80
netsh firewall add portopening TCP 80 "HTTP"

echo windows xp port 443
netsh firewall add portopening TCP 443 "HTTPS"

echo windows xp port 22
netsh firewall add portopening TCP 22 "ssh windows host"

echo windows xp port 2222
netsh firewall add portopening TCP 2222 "ssh greenbox host"

echo windows xp port 2376
netsh firewall add portopening TCP 2376 "docker admin port"

echo run tasks immediately
SchTasks /Run /TN "sshd greenbox 22"
