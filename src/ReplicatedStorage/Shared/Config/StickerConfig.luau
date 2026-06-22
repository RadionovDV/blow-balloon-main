local StickerConfig = {}

StickerConfig.Stickers = {
	-- {
	--     name      = "StickerName",
	--     rarity    = "Rare",
	--     icon      = "rbxassetid://...",
	--     productId = 0,
	-- },
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