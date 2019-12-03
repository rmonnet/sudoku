
Solving the SudoKu puzzle
=========================

Sudoku is a number based puzzle and it was just too tempting not to try to
solve it algorithmically.

Details about the Sudoku puzzle can be found on the `Sudoku Web Site`_

Sudoku uses a 9x9 grid and each location can contain a number between 1 and 9
with the following restrictions:

 #. Each row must contain all numbers between 1 and 9
 #. Each column must contain all numbers between 1 and 9
 #. Each 3x3 sub-grid must contains all numbers between 1 and 9

A puzzle is given as an incomplete grid. An example of puzzle (taken from the
`Sudoku web site`_) is given below::

        . 6 .  1 . 4  . 5 .
        . . 8  3 . 5  6 . .
        2 . .  . . .  . . 1
        
        8 . .  4 . 7  . . 6
        . . 6  . . .  3 . .
        7 . .  9 . 1  . . 4
        
        5 . .  . . .  . . 2
        . . 7  2 . 6  9 . .
        . 4 .  5 . 8  . 7 .

To solve the puzzle, one needs to fill-in the missing numbers respecting the 3 rules described above.

The solution to the example above is given here::

        9 6 3  1 7 4  2 5 8
        1 7 8  3 2 5  6 4 9
        2 5 4  6 8 9  7 3 1
        
        8 2 1  4 3 7  5 9 6
        4 9 6  8 5 2  3 1 7
        7 3 5  9 6 1  8 2 4
        
        5 8 9  7 1 3  4 6 2
        3 1 7  2 4 6  9 8 5
        6 4 2  5 9 8  1 7 3

Before we can discuss the details of the algorithms used to solve the problem, we need to go through a few definitions:

Grid
    The 9x9 matrix which contains the numbers from 1 to 9. A Grid is represented by
    an instance of the class Grid.

Location
    A point on the Grid defined by its coordinates (row,col) and its value.
    If the location already contained a number it is said to be *defined*,
    *undefined* otherwise

Box
   A 3x3 sub-grid, they are also defined by theirs coordinates (row,col).

Possibility
   The set of all possible valid value that an undefined location can take.
   This is represented by an instance of the Poss class. It contains the
   location coordinate and the set of valid possible values.

Depth
   This is used to designate the number of values in a Possibility. A Depth of
   1 means that only one new Problem can be derived from the current one if this
   location is populated.

Step
   A Step is the action of creating a new problem from a *parent* problem by
   setting the value of an undefined location. A Solution is obtained from an
   original problem and a set of steps. A Step is represented by an instance of
   the class Step.

Degree Of Freedom
   This is a measure of how many *undefined* locations are contained in a 
   problem.

Completed Problem
   A problem is said to be completed if all locations are *defined*.

Once we get these definitions, solving the puzzle (with the help of a computer is fairly simple).

The First step is to compute the possibilities for each *undefined* location on the grid.
Each location belongs to a row, a column and a box. It is easy to compute the possibilities for any *undefined* element of a row, column or box as the set of numbers 1 through 9 minus the numbers already allocated to *defined* locations in the respective row, column or box. In the example above, the list of possibilities for the first row is 2, 3, 7, 8 and 9 From this we can deduct the set of possibilities for each location as the intersection of
the possibilities for its row, column and box. In the example above, the possibilities for the location in the first row and first column are 3 and 9.

The Depth of this location is 2. Of particular interests for our algorithm are all locations of Depth 1. By definition, this single Possibility is the value that this location must take. We could pick one of these possibility, fill-in the associated location and try to solve this more limited problem, however, since all the locations of Depth 1 have only one choice then we may as well fill-in all of them at the same time. It is possible that filling more than one location at once results in an impossible problem: when two of the new values are identical for a row, column or box. In practice, it is easier to compute the new problem and then reject it if it is impossible than to try to find a subset of the possibilities of Depth 1 than is non-conflicting.

If a problem does not have any possibilities of Depth 1, then we need to derive a new problem using the Depth 2 possibilities (or higher). Since even one of these locations has at least two solutions, we cannot derive a single new problem from the current one. The solution is to derive **all** the possible problems and store them in a priority queue.

At this stage we can select the problem at the top of the queue and try to solve it using the logic described above until we get to the solution or an impossible problem. If we get to an impossible problem, we simply discard it and use the next one on the queue. Heuristically, it was found that sorting the queue by ascending number of possible child problems (max possibilities) helps speed up the algorithm.

The entire algorithm can then be seen as a derive-and-branch algorithm, where we take the most direct route when possible (all locations of depth 1) or branch otherwise (replacing the single problem with all the possible problems derived from the set of lowest depth possibilities).

The resulting algorithm is very fast, typically solving a problem with 50 degrees of freedom (i.e. 50 *undefined* locations) in about less than 25 iterations. This is fast when considered that the example given above has a number of possible child problem of the order of 140396484098418278400000 and that the solution is found after exploring only 57 child problems.

This algorithm has some limitations however, it quits after finding the first solution and does not help generate problems in the first place. But this is a story for a future blog.

If you are interested, a ruby program implementing this algorithm can be found at the following location as `source code`_ or `syntax colored html`_ (thanks to vim_).

.. _`Sudoku Web Site`: http://www.sudoku.com
.. _`source code`: http://www.knology.net/~rmonnet/code/sudoku.rb
.. _`syntax colored html`: http://www.knology.net/~rmonnet/code/sudoku.rb.html
.. _vim: http://www.vim.org

