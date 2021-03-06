import abis from '../abis'
import createLock from './createLock'
import getLock from './getLock'
import purchaseKey from './purchaseKey'
import updateKeyPrice from './updateKeyPrice'
import withdrawFromLock from './withdrawFromLock'
import configureUnlock from './configureUnlock'
import isLockManager from './isLockManager'

export default {
  createLock,
  configureUnlock,
  getLock,
  purchaseKey,
  updateKeyPrice,
  withdrawFromLock,
  isLockManager,
  version: 'v01',
  Unlock: abis.v01.Unlock,
  PublicLock: abis.v01.PublicLock,
}
