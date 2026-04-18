# C++ Auto Boilerplate (cpp-boilerplate-auto)

A lightweight, zero-configuration VS Code extension that automatically injects a competitive programming C++ boilerplate into any newly created or empty `.cpp` file. 

Stop typing `#include <bits/stdc++.h>` and start solving immediately.

## Features

* **Instant Activation:** The moment you open or create an empty `.cpp` file, your boilerplate is injected. No snippets to remember, no shortcuts to press.
* **CP Optimized:** Comes pre-loaded with the standard competitive programming setup, including fast I/O optimizations.
* **Non-Intrusive:** It checks if the file is completely empty (`length === 0`) before injecting. It will **never** overwrite your existing code if you open an older project.

### The Boilerplate

This extension injects the following code:

```cpp
#include <bits/stdc++.h>
using namespace std;


int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    
    return 0;
}