sub init()
    m.top.functionName = "run"
end sub

function run() as void
    url = m.top.url
    if url = invalid or Len(url) = 0 then
        LogError("EpisodeTask: no URL specified")
        return
    end if

    cached = CacheGet(url)
    if cached <> invalid then
        Log("EpisodeTask cache hit " + url)
        m.top.message = cached
        return
    end if

    Log("EpisodeTask requesting " + url)
    xfer = CreateObject("roUrlTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.AddHeader("User-Agent", "Mozilla/5.0")
    xfer.SetUrl(url)
    html = xfer.GetToString()
    if html = invalid then
        LogError("EpisodeTask failed to load " + url)
    else
        Log("EpisodeTask received response")
        CacheSet(url, html)
    end if
    m.top.message = html
end function
