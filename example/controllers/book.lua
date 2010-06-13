local books = {
	{name = "The Bible"};
}

function view(id)
	if not id then
		serveText("Book ID not specified!")
		return
	end

	book = books[tonumber(id)]
end

function add()
	--no view
end

