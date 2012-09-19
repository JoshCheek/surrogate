### 0.6.0

* Remove `api_method_names` and `api_method_for` from surrogates (might break your code if you relied on it, but was never advertized, and no obvious reason to use it)
* BREAKING CHANGE - Substitutability can check argument "types". This is turned on by default
* Initialize is no longer implicitly recorded (This might break something, but I don't think this feature was ever advertized, so hopefully people don't depend on it).
* BREAKING CHANGE - API method signatures are enforced (if meth takes 1 arg, you must pass it 1 arg)
* The name of a clone is the name of the parent suffixed with '.clone', unless the parent is anonymous (not set to a const), then the name is nil.
* Inspect messages are shorter and more helpful
* Inspect messages on class clones mimic the parents
