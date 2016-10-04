postMessageHandler = (event)->
  if not event.origin.match(/^https:\/\/([\w\-]+\.)*bsvecosystem\.net/) then return
  try
    request = JSON.parse(event.data)
  catch
    return
  if request.type == "tag"
    title = "FLIRT"
    url = window.location.toString()
    airports = GritsFilterCriteria.departures.get().join(", ")
    start = GritsFilterCriteria.operatingDateRangeStart.get().toISOString().split("T")[0]
    end = GritsFilterCriteria.operatingDateRangeEnd.get().toISOString().split("T")[0]
    activeTable = $('.dataTableContent').find('.active').find('.table.dataTable')
    if activeTable.length
      dataUrl = 'data:text/csv;charset=utf-8;base64,' + activeTable.tableExport(
        type: 'csv'
        outputMode: 'base64'
      )
      if window.location.pathname == "/"
        title = "Flights from #{airports} #{start} to #{end}"
      else if url.match(/simulation/)
        title = "Simulated passenger flow from #{airports} #{start} to #{end}"
      window.parent.postMessage(JSON.stringify({
        html: """<a href='#{dataUrl}'>Download Data CSV</a><br /><a target="_blank" href='#{url}'>Open FLIRT</a>"""
        title: title
      }), "*")


window.addEventListener("message", postMessageHandler, false)
