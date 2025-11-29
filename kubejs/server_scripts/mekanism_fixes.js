// Fix Mekanism crushing recipe for Ad Astra Venus Sandstone
ServerEvents.recipes(event => {
    // Remove the broken recipe
    event.remove({ id: 'mekanism:crushing/venus_sandstone_to_venus_sand' })
    
    // Add it back correctly (if the items actually exist)
    // Check if Ad Astra has venus sandstone and sand
    if (Platform.isLoaded('ad_astra')) {
        event.recipes.mekanism.crushing(
            'ad_astra:venus_sand',           // Output
            '#forge:sandstone/venus'         // Input (using proper tag)
        )
    }
})