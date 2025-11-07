interface IERC4626 {
    function asset() external view returns (address);
    function balanceOf(address) external view returns (uint256);
    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares);
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
    function convertToAssets(uint256 shares) external view returns (uint256);
}
