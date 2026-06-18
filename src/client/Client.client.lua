local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)

ReplicaClient.OnNew("PlayerData", function(replica)
	print("[Client] PlayerData received, Coins:", replica.Data.Coins)

	replica:OnSet({"Coins"}, function(new, old)
		print("[Client] Coins changed:", old, "->", new)
	end)
end)

ReplicaClient.RequestData()