### 0.6.0

* Initialize is no longer implicitly recorded.
* API method signatures are enforced (if meth takes 1 arg, you must pass it 1 arg)
* The name of a clone is the name of the parent suffixed with '.clone', unless the parent is anonymous (not set to a const), then the name is nil.
* Inspect messages are shorter and more helpful
* Inspect messages on class clones mimic the parents
