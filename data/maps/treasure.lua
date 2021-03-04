
local map = ...
local game = map:get_game()

local links = {
  linkedin="https://www.linkedin.com/profile/add?startTask=CERTIFICATION_NAME&name=Les%20fondamentaux%20du%20d%C3%A9veloppement%20web%20en%20Java%20EE&organizationId=18863041&issueYear=2021&issueMonth=2&certUrl=https%3A%2F%2Fgdufrene.github.io%2Fmooc_jee_spring%2Fcertificat_fondamentaux.html",
  facebook="https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fgdufrene.github.io%2Fmooc_jee_spring%2Fcertificat_fondamentaux.html"
}

function endChest_fb:on_opened()
  show_share_link("Facebook")
end

function endChest_in:on_opened()
  show_share_link("LinkedIn")
end

function show_share_link(share)
  game:get_hero():unfreeze()
  local box = game:get_empty_box()
  box.title = "Lien de partage "..share
  box.sprite = sol.sprite.create("qrcode/share")
  box.sprite:set_animation(share:lower())
  box:set_size(190, 200)
  sol.menu.start( game, box )
  sol.log.info("***************************************")
  sol.log.info("Partage ton certificat à l'aide de ce lien : "..links[share:lower()])
  sol.log.info("***************************************")
end
