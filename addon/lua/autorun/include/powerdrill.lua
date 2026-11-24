AddCSLuaFile()

pk_pills.packStart("Power Drill","Power Drill","icon/pill_powerdrill.png")

pk_pills.register("pill_powerdrill",{

    printName="Power Drill Massacre",
	
    model="models/driller/puppet_combo/drillerv2.mdl",
	
	modelScale="1.2",

        muteSteps = true,
	
    anims={
        default={
            idle="idle",
			run="run",
            walk="walk",
			attack="attack",
			jumpscare="attack",
            missattack="attack",
            crouch="idle",
            crouch_walk="walk",
        },
    },
	
    moveSpeed={
        walk=110,
        run=540,
        ducked=100,
    },
	
    sounds={
		melee="slender/driller/drill.wav",
                scream="slender/driller/sting1.wav",
        sound2="slender/driller/sting1.wav",
		jumpscare="slender/driller/sting2.wav",
        missattack="slender/driller/drill.wav",
    },
	

    type="ply",

    camera={
        dist=120
    },
	
    jumpPower=0,
	
    health=4444,
	
	movePoseMode="xy",
		aim={
		xPose="aim_yaw",
		yPose="aim_pitch",
		nocrosshair = true
	},
	
	canAim=function(ply,ent)
		return ent.active
	end,
	
	init = function(ply, ent)
		-- Timer to check velocity and possibly play a sound every second
		timer.Create("CheckVelocityAndPlaySound" .. ply:EntIndex(), 1, 0, function()
			if not IsValid(ply) then
				timer.Remove("CheckVelocityAndPlaySound" .. ply:EntIndex())
				return
			end
			
			local velocity = ply:GetVelocity():Length()
	
			if velocity <= 300 then
				local rand = math.random(2, 20)
	
				if rand == 2 then
					ent:PillSound("loop_stare")	
				end
			end
		end)
	end,

    --Left Click Attack Function
attack = {
    mode = 'trigger',
    func = function(ply, ent)
        local entity = nil
local targetOrigin = ent:LocalToWorld(Vector(0, 0, 50))
if SherlockHNS then
    entity = SherlockHNS.FindVictim(ply, targetOrigin, 100)
else
    for k, v in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 100)) do
                if v:IsPlayer() or v:IsNextBot() or v:IsNPC() then
                    if v == ent or v == ply then continue end
                    if (v:IsPlayer() and v:Team() ~= TEAM_SPECTATOR) or (v:IsNPC() or v:IsNextBot()) and v:Health() > 0 then
                        entity = v
                        break
                    end
                end
            end
end

if SherlockHNS and IsValid(entity) and entity:IsPlayer() then
            return pk_pills.playHNSJumpscare(ply, ent, entity, 0.4, {
                camera = "PILLSJUMPCAM",
                offset = 75,
                animation = "jumpscare",
                sound = "jumpscare",
            })
        end

        if IsValid(entity) then
            local pill = ent:GetPuppet()

            -- Handling players
            if entity:IsPlayer() then
                entity:Freeze(true)
                entity:AddFlags(FL_NOTARGET)
                entity:DrawViewModel(false)
                entity:SetActiveWeapon(nil)

                -- Start the jump scare camera effect
                net.Start('PILLSJUMPCAM')
                net.WriteEntity(pill)
                net.WriteBool(true)
                net.Send(entity)
            else
                -- Disable NPC's future thinking to simulate freezing them
                entity:NextThink(CurTime() + 1e9) 
            end

            -- Move the entity into position relative to the pill
            entity:SetPos(pill:GetPos() + pill:GetForward() * 75)

            ply:Freeze(true)

            -- Play the animation and sound for the entity performing the attack
            ent:PillAnim('jumpscare')
            ent:PillSound('jumpscare')
            timer.Simple(1.50, function()
                ent.killlineplaying = true
                ent:PillSound('killvoice')
            end)

            -- Timer to handle the next steps after the animation
            timer.Simple(0.4, function()
                if not IsValid(entity) or not IsValid(ent) then return end

                

                -- Handling NPCs
                if entity:IsNPC() or entity:IsNextBot() then
                    local headBone = entity:LookupBone("ValveBiped.Bip01_Head1")
                    if headBone then
                        entity:ManipulateBoneScale(headBone, Vector(0, 0, 0))
                    end
                end

                -- Handling Players
                if entity:IsPlayer() then
                    local finalRagdoll = ents.Create("prop_ragdoll")
                    finalRagdoll:SetModel(entity:GetModel())
                    finalRagdoll:SetPos(entity:GetPos())
                    finalRagdoll:SetAngles(entity:GetAngles())
                    finalRagdoll:Spawn()

                    -- Set ragdoll physics
                    for i = 0, entity:GetBoneCount() - 1 do
                        local phys = finalRagdoll:GetPhysicsObjectNum(i)
                        if IsValid(phys) then
                            local pos, ang = entity:GetBonePosition(i)
                            phys:SetPos(pos)
                            phys:SetAngles(ang)
                            phys:Wake()
                        end
                    end

                    -- Manipulate head bone
                    local headBone = finalRagdoll:LookupBone("ValveBiped.Bip01_Head1")
                    if headBone then
                        finalRagdoll:ManipulateBoneScale(headBone, Vector(0, 0, 0))
                    end
                end

                -- Freeze and reset player settings
                ply:Freeze(false)

                -- Kill the player or damage the NPC
                if entity:IsPlayer() then
                    entity:Kill(ply)
                    net.Start('PILLSJUMPCAM')
                    net.WriteEntity(pill)
                    net.WriteBool(false)
                    net.Send(entity)
                    entity:RemoveFlags(FL_NOTARGET)
                    entity:Freeze(false)
                    entity:DrawViewModel(true)
                else
                    entity:NextThink(CurTime()) 
                    entity:TakeDamage(1e9, ply)
                end
            end)
        else
            -- No valid target, perform normal attack animation
        end

        timer.Simple(3, function()
            ply.OnHold = false
        end)

        -- Timer to reset hold state
        timer.Simple(10, function()
            ent.killlineplaying = false
        end)
    end,
},

	attack2 = {
    mode = "trigger",
    func = function(ply, ent)
        if not SERVER then return end
        ent._dashCooldownEnd = ent._dashCooldownEnd or 0

        if CurTime() < ent._dashCooldownEnd then
            local timeLeft = math.ceil(ent._dashCooldownEnd - CurTime())
            ply:ChatPrint("Dash is on cooldown, wait " .. timeLeft .. " seconds.")
            return
        end

        local baseRun = ent.formTable.moveSpeed.run
        ent._origRunAnim  = "run"

        ent.formTable.anims.default.run = "run"
		ent.formTable.anims.default.glide = "run"
        pk_pills.setCostumeMoveSpeed(ent, nil, baseRun * 2)
        ent:PillSound("scream")

        timer.Simple(1.3, function()
            if not IsValid(ply) or not IsValid(ent) then return end

            ent.formTable.anims.default.run = ent._origRunAnim
			ent.formTable.anims.default.glide = ent._origRunAnim
            pk_pills.setCostumeMoveSpeed(ent)
        end)

        ent._dashCooldownEnd = CurTime() + 30
    end},

noragdoll=true,
	
	-- Jump Attack Spacebar Function 
    jump=function(ply,ent)

    end
}, function(form)
    -- The legacy damage branches are for Sandbox and NPCs.
    form.hnsKillAPI = true
    form.hnsAbilities = {
        { id = "attack", name = "Ataque", key = IN_ATTACK, OnUse = form.attack.func },
        { id = "dash", name = "Arrancada", key = IN_ATTACK2, cooldown = 30, duration = 1.3,
            OnUse = function(ply, ent)
                pk_pills.setCostumeMoveSpeed(ent, nil, ent.formTable.moveSpeed.run * 2)
                ent:PillSound("scream")
            end,
            OnEnd = function(ply, ent) pk_pills.setCostumeMoveSpeed(ent) end },
    }
    form.attack, form.attack2, form.reload = nil, nil, nil
end)


