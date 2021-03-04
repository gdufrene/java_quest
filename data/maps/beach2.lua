
local map = ...
local game = map:get_game()

require("scripts/util/dump")

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
	gidebessai.step = game:get_value("gidebessai_step") or 1
	local open = game:get_value("warehouse_door")
	if open == nil then open = true end
	map:set_entities_enabled("warehouse_door", open)
end

function run_step(npc, callback)
	game:start_dialog("warehouse." .. npc:get_name() .. "_" .. npc.step, function(r) 
		if callback(r) then
			npc.step = npc.step + 1
			npc:on_interaction() -- when suceed relaunch new dialog.
		end
	end)
end

function always_continue(r) 
	return true
end

function never_continue(r) 
	return false
end

function continue_when_1(r) 
	return r == 1
end

function init_database()
	res = sol.sql.query(
[[
-- reset table
drop table if exists users;

-- users schema
create table users(
  -- 'INTEGER PRIMARY KEY' acts as an autoincrement.
  -- see https://sqlite.org/autoinc.html
  id INTEGER PRIMARY KEY,
  firstname varchar(80),
  lastname varchar(80),
  email varchar(120),
  password varchar(32),
  -- a constraint on unique email is a good idea
  CONSTRAINT chk_mail UNIQUE(email)
);

-- index on email is a really good idea for performance
CREATE INDEX user_mail_idx ON users(email);

-- users data
insert into users
  (firstname,   lastname,   email,                              password  ) 
values
  ('guillaume', 'dufrene',    'guillaume.dufrene@foo.bar', 'eservices'),
  ('lionel',    'seinturier', 'lionel.seinturier@foo.bar', 'eservices'),
  ('Gide',      'Bessai',     'gidebessai@mooc.fun',       'jdbcrocks');

]])
	return res
end


function gidebessai:on_interaction()

	local back_after_intro = function()
		gidebessai.step = 2
		return false
	end

	local steps = {
		-- 1 -- intro
		always_continue,
		-- 2 -- create base ?
		continue_when_1,
		-- 3 -- SQL
		function()
			sol.log.info("Votre base sera dans le répertoire => "..os.getenv("HOME"))
			res = init_database()
			if ( res == "Ok" ) then
				self.step = self.step + 1
			end
			return true
		end,
		-- 4 -- erreur sql 
		back_after_intro,
		-- 5 -- 
		always_continue,
		-- 6 --
		function(r)
			if ( r ~= 1 ) then
				return false
			end
			res = sol.sql.query("Select * from users where email = 'gidebessai@mooc.fun'");
			if ( type(res) == "table" and table.getn(res) >= 1 ) then
				sol.log.error("gidebessai@mooc.fun est toujours dans la table users.")
				self.step = 8
				return false
			end
			if ( res ~= "Ok" ) then -- "Ok" means "no result"
				self.step = 8
				return false
			end
			self.step = self.step + 2
			return true
		end,
		-- 7 -- erreur access
		back_after_intro,
		-- 8 -- erreur resultat
		back_after_intro,
		-- 9 -- ok !
		function()
			map:set_entities_enabled("warehouse_door", false)
			game:set_value("warehouse_door", false)
			self.step = 10
			game:set_value("gidebessai_step", 10)
			return false
		end,
		-- 10 -- re-init database ?
		function(r)
			if r == 2 then return false end
			init_database()
			return false
		end

	}
	game:set_value("gidebessai_step", self.step)
	run_step(self, steps[self.step])
end

