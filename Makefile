devstart:
	iex --sname gdscan@localhost -S mix phx.server

devremote:
	iex --sname gdscanremote@localhost --remsh gdscan@localhost