local state_path = '/tmp'

local bbl = require("bbl-twitter")
local twitter_config = bbl.twitter_config

conf = {
  state_path = '/tmp',
  services = {'home'},
  interface = 'pppoe-wan',
} --defaults

local function read_file(filename)
  local f = io.open(filename, 'r')
  if not f then return nil, 'Could not open' end
  local data, err = f:read('*l')
  f:close()
  return data, err
end

local function write_file(filename, s)
  local f = io.open(filename, 'w')
  if not f then return nil, 'Could not open' end
  local data, err = f:write(s)
  f:close()
  return true
end

local function get_ip_address(ifname)
	local f = assert(io.popen('ifconfig ' .. ifname, 'r'))
	local res = assert(f:read('*a'))
	f:close()
	return string.match(res, 'inet addr:(%S*)%s')
end

local function load_conf(filename)
  local f, err = io.open(filename, 'r')
  if not f then return nil, err end
  print ('loading conf from', filename )
  for l in f:lines() do
    if l ~= string.rep(' ', #l) and not l:match('^%s*%-%-') then 
      print('>', l, pcall(loadstring('conf.' .. l:match('^%s*(.*)$'))))
    end
  end
  return true
end


twitter_config.consumer_key = 'vBK7cGYVjNP6lcHlPyO78kogJ'
twitter_config.consumer_secret = 'ScFpTd6rJwR9XHFPJn5sIoTX2KYhqNRIqOrCLhImdaBVPyFxx4'
twitter_config.token_key = read_file('token.key')
twitter_config.token_secret = read_file('token.secret')
twitter_config.screen_name = read_file('screen.name')

local client = assert(bbl.client())

if not (twitter_config.token_key and twitter_config.token_secret and twitter_config.screen_name) then 
  -- The following function will prompt on the console to visit a URL and
  -- enter a PIN for out-of-band authentication
  client:out_of_band_cli()
  print(string.format("Authorized by user '%s'. My secrets are token_key '%s' token_secret '%s'",
    client.screen_name, client.token_key, client.token_secret))
  write_file('token.key', client.token_key)
  write_file('token.secret', client.token_secret)
  write_file('screen.name', client.screen_name)
  os.exit()
end

local newconf = load_conf('twrnip.conf') or load_conf('/etc/twrnip.conf')
if not newconf then
  print ('no twrnip.conf file found, using defaults')
end

local ip = assert(get_ip_address(conf.interface))

local lines = {"#twrnip"}
for i=1, #conf.services do
  lines[#lines+1] = conf.services[i]
end
lines[#lines+1] = ip 
local s = table.concat(lines, '\n')

local oldid, err = read_file(state_path .. '/twrnip_last_id')
print ('Retrieving previous id:', oldid, err)

print ('Statusing:---------'); 
print(s)
print ('-------------------')

local i=0
repeat
  local ret, err = client:update_status(s)
  if not ret then
    i=i+1
    print ('Error statusing:', i, err)
    os.execute('sleep 60')
  end
until ret or i==10

local newid = ret:match('"id":(%d+),')
print ('Current id:', newid )
print('Saving current id:', write_file(state_path .. '/twrnip_last_id', newid))

if oldid then 
	assert(client:signed_request(
		"/1.1/statuses/destroy/"..tostring(oldid)..".json", 
		{id = tonumber(oldid)}
	))
end

