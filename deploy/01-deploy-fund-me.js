//Pas besoin de créer une main() function ni de l'appeler, le plugin s'en charge
require("dotenv").config()
const { getNamedAccounts, deployments, network } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify") //Importe uniquement network config du fichier helper grâce aux {}

//-----------1ere solution----------
/*async function deployfunc(hre) {
    console.log("")
}
module.exports.defaults = deployFunc //indique quelle fonction appeler pour le déploiement */

//-----------2eme solution----------
/* module.exports  = async (hre) => { //Fonction anonyme; plus simple
    const { getNamedAcocunts, deployments } = hre
    //hre.getNamedAccounts
    //hre.deployments
} */

//-----------3eme solution (la plus brève)-----
module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    //const ethUsdPriceFeed = networkConfig[chainId]["ethUsdPriceFeed"]
    let ethUsdPriceFeedAddress
    if (chainId == 31337)/*(developmentChains.includes(network.name))*/ {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    }

    log("----------------------------------------------------")
    log("Deploying FundMe and waiting for confirmations...")

    const args = [ethUsdPriceFeedAddress]
    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1, //Attendre la confirmation du nombre de bloc écrit dans hardhat.config ou sinon 1 block
    })

    log(`FundMe deployed at ${fundMe.address}`)

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(fundMe.address, args)
    }

    log("------------------------------")
}

module.exports.tags = ["all", "fundme"]
