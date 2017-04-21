
set TASK_USER=%1
set TASK_PASSWORD=%2
set GREENBOX_INSTALL_PATH=%3


REM SchTasks /Create /F /SC ONSTART /TN "Hello world" /ru %TASK_USER% /rp %TASK_PASSWORD% ^
REM     /TR "\"c:\Program Files\Git\bin\bash.exe\"  --login -i \"%GREENBOX_INSTALL_PATH%\hello.sh\" "


SchTasks /Create /F /SC ONSTART /TN "sshd greenbox 22"  /ru %TASK_USER% /rp %TASK_PASSWORD% /RL HIGHEST ^
    /TR "\"C:\Program Files\Git\bin\bash.exe\"  --login -i \"%GREENBOX_INSTALL_PATH%\sshd.sh\" 22"


echo windows xp UDP port 53
netsh firewall add portopening UDP 80 "DNS"
echo windows 7 UDP port 53
netsh advfirewall firewall add rule name="DNS" dir=in action=allow protocol=UDP localport=53

echo windows xp port 80
netsh firewall add portopening TCP 80 "HTTP"
echo windows 7 port 80
netsh advfirewall firewall add rule name="HTTP" dir=in action=allow protocol=TCP localport=80

echo windows xp port 443
netsh firewall add portopening TCP 443 "HTTPS"
echo windows 7 port 443
netsh advfirewall firewall add rule name="HTTPS" dir=in action=allow protocol=TCP localport=443

echo windows xp port 22
netsh firewall add portopening TCP 22 "ssh windows host"
echo windows 7 port 22
netsh advfirewall firewall add rule name="ssh windows host" dir=in action=allow protocol=TCP localport=22

echo windows xp port 2222
netsh firewall add portopening TCP 2222 "ssh greenbox host"
echo windows 7 port 2222
netsh advfirewall firewall add rule name="ssh greenbox host" dir=in action=allow protocol=TCP localport=2222

echo windows xp port 2376
netsh firewall add portopening TCP 2376 "docker admin port"
echo windows 7 port 2376
netsh advfirewall firewall add rule name="docker admin port" dir=in action=allow protocol=TCP localport=2376

echo run tasks immediately
SchTasks /Run /I /TN "sshd greenbox 22"
