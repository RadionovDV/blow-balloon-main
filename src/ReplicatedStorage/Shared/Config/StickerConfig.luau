local StickerConfig = {}

StickerConfig.Stickers = {
	 {
		name      = "Lightning",
	    rarity    = "Common",
		icon      = "rbxassetid://81343577199269",
		productId = 3606083242,
	},
	{
		name      = "Skull",
		rarity    = "Rare",
		icon      = "rbxassetid://98766357122025",
		productId = 3606083277,
	},
	{
		name      = "Pin In Heart",
		rarity    = "Legendary",
		icon      = "rbxassetid://109935171637842",
		productId = 3606083303,
	},
}

function StickerConfig.GetByProductId(productId)
	for _, sticker in ipairs(StickerConfig.Stickers) do
		if sticker.productId == productId then
			return sticker
		end
	end
	return nil
end

return StickerConfig