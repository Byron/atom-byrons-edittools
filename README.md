The **Byron's EditTools** atom package provides a variety of features designed to make developers more productive. These are made to be intuitive and smart, thus doing automatically what you could not have done better manually.

# Features
* **Expand and Shrink**
 - allows to grow and shrink your selection around the cursor(*s*) of your document, moving along its logical hierarchy.
* **Where Am I ?** (*TBD*)
 - Visualize the scope one is in right now. This helps with white-space sensitive languages where it can become difficult to make out the scope you are currently in, e.g. `myFunc() -> for x in y -> if x -> while x-- -> if x % 2`
* **Toggle Plugins** (*TBD*)
 - Help in pairing situations and allow possibly intrusive plugins to be easily toggled on or off.
 - If [VMP](https://github.com/t9md/atom-vim-mode-plus) is used, it might be difficult for anyone not used to vim to operate Atom, and just deactivating the plugin quickly seems like a nice thing to have.

# Status: Incubation [![Build Status](https://travis-ci.org/Byron/atom-byrons-edittools.svg?branch=master)](https://travis-ci.org/Byron/atom-byrons-edittools)

I just starting looking into solving this problem, there is no functionality just yet.

# Project Design Goals
* **Syntax-Sensitive**
 - It tries to get as close as possible to knowing the AST of the document, see [this post][atom-io-post1] for an idea.
* **Adaptable to all Languages**
 - It should be easy to adjust it to work with various languages. Depending on how it will work, it will need additional information to help it deal with the syntax information it gets from *Atom*.
* **runtime-costs don't grow with document size**
 - Its performance is not relative to the documents size, but is only affected by the costs to compute the actual expansion.
* **TDD**
 - Each line of code is motivated by a test, which would fail if it is altered.
* **Multi-Cursor Support**
 - could easily be implemented with single-cursor solution, adding each selection to the existing one.
* **Multiple grammars per file**
 - Especially markdown makes it easy to embed other file formats. We deal with it and treat it as embedded document.

# Inspired By

* [Atom Expand][github-atom-expand]
* [Atom Select Scope][github-select-scope]
* [Sublime Expand Region][github-sublime-expand]
* IntelliJ's excellent implementation (*it certainly has a complete AST for document traversal*)

[atom-io-post1]: https://discuss.atom.io/t/scope-aware-expanding-selection-using-alt-up-like-in-intellij/8228/6
[github-atom-expand]: https://github.com/aki77/atom-expand-region
[github-sublime-expand]: https://github.com/aronwoost/sublime-expand-region
[github-select-scope]: https://github.com/wmadden/select-scope
