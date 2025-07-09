sub init()
    m.top.functionName = "run"
end sub

function run() as void
    query = m.top.query
    if query = invalid or Len(query) = 0 then
        LogError("SearchTask: empty query")
        return
    end if
    base = m.top.baseUrl
    transfer = CreateObject("roUrlTransfer")
    encoded = transfer.Escape(query)
    url = base + "/index.php?menu=search&query=" + encoded

    cached = CacheGet(url)
    if cached <> invalid then
        Log("SearchTask cache hit " + url)
        m.top.message = cached
        return
    end if

    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.AddHeader("User-Agent", "Mozilla/5.0")
    transfer.SetUrl(url)
    Log("SearchTask requesting " + url)
    html = transfer.GetToString()
    if html = invalid then
        LogError("SearchTask failed to load " + url)
    else
        Log("SearchTask received response")
        CacheSet(url, html)
    end if
    m.top.message = html
end function
