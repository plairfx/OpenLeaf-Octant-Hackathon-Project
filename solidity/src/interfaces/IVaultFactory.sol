import {DataTypes} from "src/types/DataTypes.sol";

interface IVaultFactory {
    function createVault(
        DataTypes.ProjectReg memory RG
    ) external returns (address, address);
}
