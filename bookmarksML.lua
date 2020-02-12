function descriptor()
   return {
      title = "BookmarksML",
      version = "1.0",
      author = "Michal Lewicki",
      url = "",
      shortdesc = "BookmarksML",
      description = "This extension allows saving bookmarks for media files",
      capabilities = {"menu", "input-listener", "meta-listener", "playing-listener"}
   }
end

bookmarkCounter = 0
mainDialog = nil
bookmarksList = nil
inputObject = nil
bookmarksNames = {}
bookmarksTimes = {}
editDialog = nil
selectedIndex = 0
nameTextInput = nil

function activate()
   inputObject = vlc.object.input()
   loadBookmarks()
   createMenu()
end

function menu()
   return {"Show dialog"}
end

function trigger_menu(id)
   if mainDialog ~= nil then mainDialog:delete() end
   createMenu()
end

function handleError(msg)
   if mainDialog ~= nil then
      mainDialog:delete()
   end
   vlc.msg.dbg("Error dialog with message: "..msg)
   local dialog = vlc.dialog("ERROR!")
   dialog.add_label(dialog, msg)
end

function createMenu()
   vlc.msg.dbg("Creating menu")
   mainDialog = vlc.dialog("Bookmarks")
   mainDialog.add_label(mainDialog, "Boookmarks for this file", 1, 1, 2, 1)
   bookmarksList = mainDialog.add_list(mainDialog, 1, 2, 2, 1)
   local addButton = mainDialog.add_button(mainDialog, "Add", addBookmark, 1, 3, 1, 1)
   local removeButton = mainDialog.add_button(mainDialog, "Remove", removeBookmark, 2, 3, 1, 1)
   local editButton = mainDialog.add_button(mainDialog, "Edit", editBookmark, 1, 4, 1, 1)
   local goButton = mainDialog.add_button(mainDialog, "Go", goToBookmark, 2, 4, 1, 1)
   displayBookmarks()
end

function addBookmark()
   item = vlc.input.item()
   currentMediaName = item:name()
   vlc.msg.dbg(currentMediaName)
   currentTime = vlc.var.get(inputObject, "position")
   vlc.msg.dbg(currentTime)
   bookmarksSize = #bookmarksNames + 1
   bookmarkCounter = bookmarkCounter + 1
   bookmarkName = "Bookmark"..bookmarkCounter
   vlc.msg.dbg(bookmarkName)
   bookmarksTimes[bookmarksSize] = currentTime
   bookmarksNames[bookmarksSize] = bookmarkName
   displayBookmarks()
   saveBookmarks()
end

function removeBookmark()
   local index = getSelectedBookmarkIndex()
   table.remove(bookmarksTimes, index)
   table.remove(bookmarksNames, index)
   displayBookmarks()
   saveBookmarks()
end

function editBookmark()
   selectedIndex = getSelectedBookmarkIndex()
   if mainDialog ~= nil then mainDialog:delete() end
   editDialog = vlc.dialog("Edit")
   editDialog.add_label(editDialog, "Enter new name: ", 1, 1, 2, 1)
   nameTextInput = editDialog.add_text_input(editDialog, "", 1, 2, 2, 1)
   editDialog.add_button(editDialog, "OK", acceptNewName, 1, 3, 1, 1)
   editDialog.add_button(editDialog, "Cancel", cancelNewName, 2, 3, 1, 1)
end

function goToBookmark()
   local index = getSelectedBookmarkIndex()
   vlc.msg.dbg(index)
   vlc.var.set(inputObject, "position", bookmarksTimes[index])
end

function displayBookmarks()
   bookmarksList:clear()
   for idx, text in pairs(bookmarksNames) do
      local currentTime = bookmarksTimes[idx]
      bookmarksList:add_value(text.." - "..currentTime, idx)
   end
end

function getSelectedBookmarkIndex()
   local selectedBookmark = bookmarksList:get_selection()
   local index = 0
   for key, value in pairs(selectedBookmark) do
      index = key
   end
   return index
end

function acceptNewName()
   newNameText = nameTextInput:get_text()
   bookmarksNames[selectedIndex] = newNameText
   if editDialog ~= nil then editDialog:delete() end
   saveBookmarks()
   createMenu()
end

function cancelNewName()
   if editDialog ~= nil then editDialog:delete() end
   createMenu()
end

function getMediaPath()
   path = vlc.playlist.get(vlc.playlist.current()).path
   path = string.gsub(path, "file:///", "")
   vlc.msg.dbg(path)
   return path
end

function saveBookmarks()
   path = getMediaPath()
   file = io.open(path.."bmk", "w")
   for idx, text in pairs(bookmarksNames) do
      -- file:write("ETSET")
      file:write(text,"|", bookmarksTimes[idx], "\n")
   end
   file:flush()
   file:close()
end

function loadBookmarks()
   path = getMediaPath()
   file = io.open(path.."bmk", "r")
   if file ~= nil then
      for line in file:lines() do
         if line ~= nil then
            bookmarkCounter= bookmarkCounter + 1
            vlc.msg.dbg(line)
            from, to = string.find(line, "|")
            vlc.msg.dbg(from)
            vlc.msg.dbg(to)
            name = string.sub(line, 0, to - 1)
            time_ = string.sub(line, to + 1)
            bookmarksNames[bookmarkCounter] = name
            bookmarksTimes[bookmarkCounter] = time_
            vlc.msg.dbg(name)
            vlc.msg.dbg(time_)
         end
      end
      file:flush()
      file:close()
   end
end