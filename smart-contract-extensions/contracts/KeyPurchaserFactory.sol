pragma solidity 0.5.17;

import './KeyPurchaser.sol';
import 'hardlydifficult-ethereum-contracts/contracts/proxies/Clone2Factory.sol';
import 'hardlydifficult-ethereum-contracts/contracts/proxies/Clone2Probe.sol';
import 'unlock-abi-7/IPublicLockV7.sol';

/**
 * @notice A factory for creating keyPurchasers.
 * @dev This contract acts as a registry to discover purchasers for a lock
 * and by creating each purchaser itself, it's a single tx to deploy and initialize and this guarantees
 * a consistent implementation and that it was created by the lock owner.
 */
contract KeyPurchaserFactory is Clone2Probe
{
  using Clone2Factory for address;
  //using Clone2Probe for address; TODO

  event KeyPurchaserCreated(address indexed forLock, address indexed keyPurchaser);

  /**
   * @notice The implementation for minimal proxies to use.
   */
  address public keyPurchaserTemplate;

  /**
   * @notice The registry of available keyPurchases for a given lock.
   */
  mapping(address => address[]) public lockToKeyPurchasers;

  constructor() public
  {
    keyPurchaserTemplate = address(new KeyPurchaser());
  }

  function _getClone2Salt(
    IPublicLockV7 _lock,
    uint _maxKeyPrice,
    uint _renewWindow,
    uint _renewMinFrequency
  ) private pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(address(_lock), _maxKeyPrice, _renewWindow, _renewMinFrequency));
  }

  /**
   * @notice Returns the address for a keyPurchaser given the terms.
   * @dev This works whether or not the keyPurchaser has actually been deployed yet.
   */
  function getExpectedAddress(
    IPublicLockV7 _lock,
    uint _maxKeyPrice,
    uint _renewWindow,
    uint _renewMinFrequency
  ) external view
    returns (address)
  {
    bytes32 salt = _getClone2Salt(_lock, _maxKeyPrice, _renewWindow, _renewMinFrequency);
    return getClone2Address(keyPurchaserTemplate, salt);
  }

  /**
   * @notice Deploys a new KeyPurchaser for a lock and stores the address for reference.
   */
  function deployKeyPurchaser(
    IPublicLockV7 _lock,
    uint _maxKeyPrice,
    uint _renewWindow,
    uint _renewMinFrequency
  ) public
  {
    // This require is not strictly necessary, but helps to maintain trust when surfacing these
    // options on the frontend.
    require(_lock.isLockManager(msg.sender), 'ONLY_LOCK_MANAGER');

    bytes32 salt = _getClone2Salt(_lock, _maxKeyPrice, _renewWindow, _renewMinFrequency);
    address purchaser = keyPurchaserTemplate.createClone2(salt);

    KeyPurchaser(purchaser).initialize(_lock, msg.sender, _maxKeyPrice, _renewWindow, _renewMinFrequency);
    lockToKeyPurchasers[address(_lock)].push(purchaser);
    emit KeyPurchaserCreated(address(_lock), purchaser);
  }

  /**
   * @notice Returns all the KeyPurchasers for a given lock.
   * @dev Some KeyPurchasers in this list may have been disabled or stopped.
   */
  function getKeyPurchasers(
    address _lock
  ) public view
    returns (address[] memory)
  {
    return lockToKeyPurchasers[_lock];
  }

  /**
   * @notice Returns the number of available keyPurchasers for a given lock.
   */
  function getKeyPurchaserCount(
    address _lock
  ) public view
    returns (uint)
  {
    return lockToKeyPurchasers[_lock].length;
  }
}
