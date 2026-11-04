-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- External monitor connected: use only it, laptop panel off (lid open or closed).
o.launch_on_start(os.getenv("HOME") .. "/.local/bin/external-only")
