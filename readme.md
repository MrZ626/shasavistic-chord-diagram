# SVG Shasavistic Chord Graph Generator

|                   |                   |                     |                             |
| :---------------: | :---------------: | :-----------------: | :-------------------------: |
| ![e1](/img/1.svg) | ![e2](/img/2.svg) |  ![e3](/img/3.svg)  |      ![e4](/img/4.svg)      |
| **(2(3r),3r(2))** | **(2.,3r(-2x))**  | **(2.(3(-4r(3))))** | **(1.(1),4(-2),5(-3),6,7)** |

![chords](/img/chords.png)

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

|  Chord  |        Name        |        Graph        |
| :-----: | :----------------: | :-----------------: |
| (?)Maj  |     `x(2,3r)`      |  ![1](/img2/1.svg)  |
| (?)Min  |    `x(2(-3r))`     |  ![2](/img2/2.svg)  |
| (?)Maj7 |  `x(2(3r),3r(2))`  |  ![3](/img2/3.svg)  |
| (?)Min7 |   `x(2(-3r(2)))`   |  ![4](/img2/4.svg)  |
|  (?)7   | `x(2,3r,-2.(-2))`  |  ![5](/img2/5.svg)  |
| (?)dim  | `.(2,3xr,-2.(-2))` |  ![6](/img2/6.svg)  |
| (?)aug  |     `x(3(3))`      |  ![7](/img2/7.svg)  |
| (?)sus2 |     `x(2(2))`      |  ![8](/img2/8.svg)  |
| (?)sus4 |     `(2x(2))`      |  ![9](/img2/9.svg)  |
| (?)add4 |    `x(2(2),3r)`    | ![10](/img2/10.svg) |

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
