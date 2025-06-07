# SVG Shasavistic Chord Graph Generator

|                                  |                                  |                                  |
| :------------------------------: | :------------------------------: | :------------------------------: |
| ![example1](/image/output_1.svg) | ![example2](/image/output_2.svg) | ![example3](/image/output_3.svg) |
|          (2(3r),3r(2))           |         (2.(3(-4r(3))))          |         (1,2,3,4,5,6,7)          |

![example_image](/image/chords_example.png)

> Screenshot taken from [this video](https://youtu.be/8nxWoh4NBeE) (youtube)

Environment: Lua

Usage: `lua chordGen.lua "[chord1]" "[chord2]" ...`

SVG files will be created at current directory.

## Syntax

`0/1/2/3/4/5/6/7`: note

0`(...)`: note groups (separated by comma)

`-`0: move down

0`r`: put at right side

0`l`: put at left side

0`.`: skipped note

0`x`: explicitly specify the root note

## Other Examples

| Chord   | Name               |
| ------- | ------------------ |
| (?)Maj  | `(2,3r)`           |
| (?)Min  | `(2(-3r))`         |
| (?)Maj7 | `(2(3r),3r(2))`    |
| (?)Min7 | `(2(-3r(2)))`      |
| (?)7    | `(2,3r,-2.(-2))`   |
| (?)dim  | `.(2,3xr,-2.(-2))` |
| (?)aug  | `(3(3))`           |
| (?)sus2 | `(2(2))`           |
| (?)sus4 | `(2x(2))`          |
| (?)add4 | `(2(2),3r)`        |

## Tutorial

The basic unit looks like:

`0(...)`

where `0` is the movement, and `(...)` contains more notes with same format based on it.

Major chord example:

It's composed of three notes:  
Root note `0`  
Root note with upward `2D movement`  
Root note with upward `3D movement`

So the chord looks like:

`0(2,3)`

Where `0` is the root note, and `2` and `3` are the notes based on it.

First number `0` can be omitted, so final result is:

`(2,3)`

We can notice that note `3` overlaps with the note `2`, so we move it to `R`ight side:

`(2,3r)`

Minor chord example:

`(2(-3))`

Note `3` is based on note `2`, so it's put in parentheses after `2`.  
And it goes down, so there's a minus sign before it.
