module GHC.Unit.Module.Env where

import GHC.Prelude ()
import GHC.Types.Unique.FM

type ModuleNameEnv elt = UniqFM elt
