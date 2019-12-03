#!/usr/bin/env ruby

require 'fox14'
require 'date'

require 'sudoku'
require 'yaml'

include Fox

class TableWindow < FXMainWindow

    def initialize(app)
        # Call the base class initializer first
        super(app, "Sudoku Solver", nil, nil, DECOR_ALL, 0, 0, 0, 0)

        # Tooltip
        tooltip = FXToolTip.new(getApp())

        # Menubar
        menubar = FXMenuBar.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)


        # Separator
        FXHorizontalSeparator.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|SEPARATOR_GROOVE)

        # Contents
        contents = FXVerticalFrame.new(self, LAYOUT_SIDE_TOP|FRAME_NONE|LAYOUT_FILL_X|LAYOUT_FILL_Y)

        frame = FXVerticalFrame.new(contents,
            FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y) do |f|
            f.padLeft = 0
            f.padRight = 0
            f.padTop = 0
            f.padBottom = 0
        end

        # Table
        @table = FXTable.new(frame, nil, 0,
        TABLE_NO_COLSELECT|TABLE_NO_ROWSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y|HSCROLLER_NEVER|VSCROLLER_NEVER)
        #0,0,0,0, 2,2,2,2)

        @table.font = FXFont.new(getApp(), "arial", 12, FONTWEIGHT_BOLD,
            FONTSLANT_REGULAR, FONTENCODING_DEFAULT)

        @table.visibleRows = 9
        @table.visibleColumns = 9
        @table.selBackColor = @table.backColor
        @table.selTextColor = @table.textColor

        @table.columnHeaderHeight = 0
        @table.rowHeaderWidth = 0
        @table.defColumnWidth = 30
        @table.showVertGrid(true)
        @table.showHorzGrid(true)

        @table.setTableSize(9, 9)

        @table.setBackColor(FXRGB(255, 255, 255))
        #@table.setCellColor(0, 0, FXRGB(255, 255, 255))
        #@table.setCellColor(0, 1, FXRGB(255, 220, 220))
        #@table.setCellColor(1, 0, FXRGB(220, 255, 220))
        #@table.setCellColor(1, 1, FXRGB(220, 220, 255))

        # Initialize the scrollable part of the table
        (0..8).each do |r|
            (0..8).each do |c|
                @table.setItemText(r, c, "")
                @table.setItemJustify(r, c, FXTableItem::CENTER_X | FXTableItem::CENTER_Y)
                bstyle = 0
                bstyle |= FXTableItem::TBORDER if r % 3 == 0
                bstyle |= FXTableItem::BBORDER if r % 3 == 2
                bstyle |= FXTableItem::LBORDER if c % 3 == 0
                bstyle |= FXTableItem::RBORDER if c % 3 == 2
                @table.getItem(r, c).borders= bstyle
            end
        end

        statusFrame = FXHorizontalFrame.new(contents,
            FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X) do |f|
            f.padTop = 2
            f.padBottom = 2
        end

        #FXLabel.new(statusFrame, "Status:", nil, JUSTIFY_LEFT)

        @statusField = FXTextField.new(statusFrame, -1, nil, 0,
            JUSTIFY_LEFT|TEXTFIELD_READONLY|LAYOUT_FILL_X)
        @statusField.backColor = statusFrame.backColor

        #statusline
        #@statusline = FXStatusLine.new(frame)
        #@statusline.normalText = "Hello"

        # File Menu
        filemenu = FXMenuPane.new(self)
        FXMenuCommand.new(filemenu, "Open\tCtl-O").connect(SEL_COMMAND, method(:onCmdOpen))
        FXMenuCommand.new(filemenu, "Save as...\tCtl-S").connect(SEL_COMMAND, method(:onCmdSaveAs))
        FXMenuCommand.new(filemenu, "&Quit\tCtl-Q", nil, getApp(), FXApp::ID_QUIT)
        FXMenuTitle.new(menubar, "&File", nil, filemenu)

        # Options Menu
        solvermenu = FXMenuPane.new(self)
        FXMenuCommand.new(solvermenu, "Step\tCtl-1").connect(SEL_COMMAND, method(:onCmdStep))
        FXMenuCommand.new(solvermenu, "Start\tCtl-2").connect(SEL_COMMAND, method(:onCmdStart))
        FXMenuCommand.new(solvermenu, "Stop\tCtl-3").connect(SEL_COMMAND, method(:onCmdStop))
        FXMenuCommand.new(solvermenu, "Analyze\tCtl-A").connect(SEL_COMMAND, method(:onCmdAnalyze))
        FXMenuCommand.new(solvermenu, "Reset\tCtl-R").connect(SEL_COMMAND, method(:onCmdReset))
        FXMenuCommand.new(solvermenu, "Reload\tCtl-L").connect(SEL_COMMAND, method(:onCmdReload))
        FXMenuCommand.new(solvermenu, "Set as Problem\tCtl-N").connect(SEL_COMMAND, method(:onCmdSetAsProblem))
        FXMenuCommand.new(solvermenu, "Skip Solution\tCtl-K").connect(SEL_COMMAND, method(:onCmdSkipSolution))
        FXMenuCommand.new(solvermenu, "Get Web Problem\tCtl-W").connect(SEL_COMMAND, method(:onCmdGetWebProblem))
        FXMenuTitle.new(menubar, "&Solver", nil, solvermenu)

        # Manipulations Menu
        #manipmenu = FXMenuPane.new(self)
        #FXMenuTitle.new(menubar, "&Manipulations", nil, manipmenu)

        @current_r = 0
        @current_c = 0
        @running = false
        @filename = nil
        @nb_sol = 0

        puts "ARGV= #{ARGV.join(", ")}"

        if ARGV.length == 0
            grid = []
            (0..8).each { |r| grid.push(Array.new(9, 0)) }
            @initial_problem = Sudoku.new(grid)
            @solver = Solver.new(@initial_problem)
            fillGrid
        else
            loadFile(ARGV[0])
        end
    end


    def onCmdSetAsProblem(sender, sel, ptr)
        return if @running
        new_grid = []
        (0..8).step do |r|
            new_row = []
            (0..8).step do |c|
                v = @table.getItemText(r, c).to_i
                if v >= 1 and v <= 9 then
                    new_row.push(v)
                else
                    new_row.push(0)
                end
            end
            new_grid.push(new_row)
        end
        @initial_problem = Sudoku.new(new_grid)
        @solver= Solver.new(@initial_problem)
        fillGrid
    end

    def onCmdGetWebProblem(sender, sel, ptr)
        return if @running
        new_grid = get_puzzle_grid(4)
        @initial_problem = Sudoku.new(new_grid)
        @solver = Solver.new(@initial_problem)
        fillGrid
    end

    def onCmdSkipSolution(sender, sel, ptr)
        return if @running
        return if @solver.nb_problems < 2
        fillGrid if @solver.pop_solution
    end

    def onCmdStart(sender, sel, ptr)
        return if @running
        @running = true
        getApp().addChore(method(:onCmdSolve))
    end

    def onCmdStep(sender, sel, ptr)
        return unless @solver
        @solver.step(false)
        fillGrid
    end

    def onCmdStop(sender, sel, ptr)
        @running = false
    end

#    def onChore(sender, sel, ptr)
#        v = @table.getItemText(@current_r, @current_c).to_i
#        @table.setItemText(@current_r, @current_c, "#{v+1}")
#        @current_r += 1
#        if @current_r > 8 then
#            @current_r = 0
#            @current_c = (@current_c + 1) % 9
#        end
#        getApp().addChore(method(:onChore)) if @running
#    end

    def onCmdSolve(sender, sel, ptr)
        return unless @solver
        @solver.step(false)
        fillGrid
        if @solver.done?
            @running = false
            solution = @solver.solution
            if solution
                @nb_sol += 1
                puts "solution #{@nb_sol} is:"
                puts solution
            end
        end
        getApp().addChore(method(:onCmdSolve)) if @running
    end

    # Create and show this window
    def create
        super
        show(PLACEMENT_SCREEN)
    end

    def fillGrid
        #@statusline.normalText = @solver.status
        @statusField.text = @solver.status
        return if @solver.nb_problems == 0
        grid = @solver.best_problem.grid
        (0..8).each do |r|
            (0..8).each do |c|
                v = grid[r,c] > 0 ? "#{grid[r,c]}" : ""
                @table.setItemText(r, c, v)
                @table.setItemJustify(r, c, FXTableItem::CENTER_X | FXTableItem::CENTER_Y)
            end
        end
    end

    def loadFile(filename)
        File.open(filename) do |f|
            array = YAML.load(f)
            @initial_problem = Sudoku.new(array)
            @solver= Solver.new(@initial_problem)
            fillGrid
        end
    end

    def saveFile(filename)
        File.open(filename, "w") do |f|
            f.puts(@initial_problem.grid.inspect)
        end
    end

    def onCmdOpen(sende, sel, ptr)
        opendialog = FXFileDialog.new(self, "Open Sudoku Problem")
        opendialog.selectMode = SELECTFILE_EXISTING
        opendialog.patternList = ["*.sdk"]
        #opendialog.currentPattern = ["All problems (*.sdk)"]
        #opendialog.filename = @filename
        if opendialog.execute != 0
            @nb_sol = 0
            @filename = opendialog.filename
            loadFile(opendialog.filename)
        end
        return 1
    end

    # Save As
    def onCmdSaveAs(sender, sel, ptr)
        savedialog = FXFileDialog.new(self, "Save Document")
        savedialog.selectMode = SELECTFILE_ANY
        savedialog.patternList = ["*.sdk"]
        savedialog.filename = @filename
        if savedialog.execute != 0
            filename = savedialog.filename
            if File.exists?(filename)
                if MBOX_CLICKED_NO == FXMessageBox.question(self, MBOX_YES_NO,
                    "Overwrite Document", "Overwrite existing document: #{filename}?")
                    return 1
                end
            end
            saveFile(filename)
            @filename = filename
            end
    return 1
    end

    def onCmdAnalyze(sender, sel, ptr)
        return if @running
        puts @solver.analyze
    end

    def onCmdReset(sender, sel, ptr)
        return unless @initial_problem
        @running = false
        @nb_sol = 0
        @solver = Solver.new(@initial_problem)
        fillGrid
    end

    def onCmdReload(sender, sel, ptr)
        return unless @filename
        @running = false
        @nb_sol = 0
        loadFile(@filename)
    end

end

# Start the whole thing
if __FILE__ == $0
    # Make application
    application = FXApp.new("TableApp", "FoxTest")

    # Make window
    TableWindow.new(application)

    # Create app
    application.create

    # Run
    application.run
end
