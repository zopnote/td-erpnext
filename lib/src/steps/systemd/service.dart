import '../systemd.dart';

String recurringService(String executablePath, String argument) =>
    """
[Unit]
Description=Recurring service for $serviceName
After=network.target

[Service]
Type=oneshot
User=root
Group=root
ExecStart=$executablePath $argument
""";

String timerService(String schedule) =>
    """
[Unit]
Description=Timer for $serviceName

[Timer]
OnCalendar=$schedule
Persistent=true

[Install]
WantedBy=timers.target
""";

String bootService(String exePath, String argument) =>
    """
[Unit]
Description=Boot service for $serviceName
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=$exePath $argument
Restart=on-failure

[Install]
WantedBy=multi-user.target
""";
