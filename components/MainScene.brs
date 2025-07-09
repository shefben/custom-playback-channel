' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

'Main Scene Initialization with menu and video.
sub init()
    m.player = m.top.FindNode("Video")
    m.list = m.top.FindNode("MenuList")
    m.searchBox = m.top.FindNode("SearchBox")
    m.searchButton = m.top.FindNode("SearchButton")
    m.episodeButton = m.top.FindNode("EpisodeButton")
    m.hostsButton = m.top.FindNode("HostsButton")
    m.poster = m.top.FindNode("Poster")
    m.hostLabel = m.top.FindNode("HostMessage")
    m.hostTimer = m.top.FindNode("HostMessageTimer")
    m.hostTimer.ObserveField("fire", "onHostTimerFire")
    m.spinner = m.top.FindNode("Spinner")
    m.statusLabel = m.top.FindNode("StatusLabel")
    m.searchTask = m.top.FindNode("SearchTaskNode")
    m.searchTask.ObserveField("message", "onSearchResults")
    m.episodeTask = m.top.FindNode("EpisodeTaskNode")
    m.episodeTask.ObserveField("message", "onEpisodeResults")
    m.hostTask = m.top.FindNode("HostTaskNode")
    m.hostTask.ObserveField("message", "onHostResults")
    m.searchButton.ObserveField("buttonSelected", "onSearchPress")
    if m.episodeButton <> invalid
        m.episodeButton.ObserveField("buttonSelected", "onEpisodeButtonPress")
    end if
    if m.hostsButton <> invalid
        m.hostsButton.ObserveField("buttonSelected", "onHostsButtonPress")
    end if
    m.hostList = m.top.FindNode("HostList")
    if m.hostList <> invalid
        m.hostList.ObserveField("itemSelected", "onHostListSelect")
    end if
    m.list.ObserveField("itemFocused", "onItemFocused")
    m.player.ObserveField("state", "onVideoStateChanged")
    m.player.visible = false
    m.searchBox.setFocus(true)
    m.itemfocused = 0
    m.baseUrl = "https://hydrahd.sh"
    m.searchTask.baseUrl = m.baseUrl
    m.isEpisodeList = false
    m.pendingContent = invalid
    m.resumeOnMenuClose = false
    m.prefetchTasks = []
end sub

'Handle remote control key presses'
function onKeyEvent(key as String, press as Boolean) as boolean
  print key + ":" ; press
  if press
    if key = "options"
      if m.hostList.visible
        HideHostList()
      else
        ShowHostList()
      end if
      return true
    else if key = "up" and m.list.visible = true and not m.searchBox.hasFocus()
      m.searchBox.setFocus(true)
      return true
    else if key = "down" and m.searchBox.hasFocus()
      m.list.setFocus(true)
      return true
    else if key = "OK"
      if m.searchBox.hasFocus()
        onSearchPress()
        return true
      end if
        if m.list.visible
            if m.list.ItemFocused = m.itemfocused and not m.isEpisodeList
              m.list.visible = false
              ResumeFromMenu()
              m.searchBox.setFocus(true)
          else if m.isEpisodeList
            epContent = m.list.content.getChild(m.list.itemfocused)
            if epContent.isHeader = true return true
            m.itemfocused = m.list.itemfocused
            StopVideo()
            m.pendingContent = epContent
            m.spinner.visible = true
            m.hostTask.url = epContent.url
            m.hostTask.control = "run"
          else
            m.itemfocused = m.list.itemfocused
            selectedContent = m.list.content.getChild(m.list.itemfocused)
            m.pendingContent = selectedContent
            m.spinner.visible = true
            m.episodeTask.url = selectedContent.url
            m.episodeTask.control = "run"
          end if
        end if
    else if key = "play"
      if m.player.control = "pause"
        ResumeVideo()
      else
        PauseVideo()
      end if
    else if key = "fastforward"
      FastForward()
      return true
    else if key = "rewind"
      Rewind()
      return true
    else if key = "stop"
      StopVideo()
      return true
    else if key = "back"
      if m.list.visible = true and m.isEpisodeList = true
        m.list.content = m.originalContent
        m.isEpisodeList = false
        m.list.jumpToItem(m.itemfocused)
        return true
        else if m.list.visible = true
          m.list.visible = false
          ResumeFromMenu()
          m.searchBox.setFocus(true)
        return true
      else
        m.list.visible = true
        m.list.setfocus(true)
        PauseForMenu()
        return true
      end if
    else
      print key
    end if
  else
    m.list.setfocus(true)
  end if
end function

'load video list from web page'

sub LoadVideoList(html as String)
    listContent = CreateObject("roSGNode", "ContentNode")
    results = ParseSearchResults(html, m.baseUrl)
    for each item in results
        node = listContent.CreateChild("ContentNode")
        node.title = item.title
        node.url = item.pageUrl
        node.description = "mp4"
        node.hdposterurl = item.imgUrl
        node.AddField("hosts", "string", true)
        node.hosts = [ item.pageUrl ]
    end for

    m.list.content = listContent
    m.originalContent = listContent
    PrefetchEpisodes(listContent)
    m.list.visible = true
    m.list.setFocus(true)
    PauseForMenu()
    m.player.visible = false
end sub

sub onSearchPress()
    query = m.searchBox.text
    if query = invalid or Len(query) = 0 return
    ShowStatusMessage("Searching...")
    m.spinner.visible = true
    m.searchTask.query = query
    m.searchTask.control = "run"
  end sub

sub onEpisodeButtonPress()
    url = m.searchBox.text
    if url = invalid or Len(url) = 0 return
    ShowStatusMessage("Loading episodes...")
    m.spinner.visible = true
    m.episodeTask.url = url
    m.episodeTask.control = "run"
end sub

sub onHostsButtonPress()
    url = m.searchBox.text
    if url = invalid or Len(url) = 0 return
    ShowStatusMessage("Loading hosts...")
    m.spinner.visible = true
    m.hostTask.url = url
    m.hostTask.control = "run"
end sub

  sub SearchVideos(query as String)
    if query = invalid or Len(query) = 0 return
    transfer = CreateObject("roUrlTransfer")
    encoded = transfer.Escape(query)
    url = m.baseUrl + "/index.php?menu=search&query=" + encoded
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.AddHeader("User-Agent", "Mozilla/5.0")
    transfer.SetUrl(url)
    html = transfer.GetToString()
    if html <> invalid
        LoadVideoList(html)
    end if
  end sub

sub onSearchResults()
    m.spinner.visible = false
    ShowStatusMessage("Search complete")
    html = m.searchTask.message
    if html <> invalid and Len(html) > 0
        LoadVideoList(html)
    else
        LogError("SearchTask returned no results")
        empty = CreateObject("roSGNode", "ContentNode")
        n = empty.CreateChild("ContentNode")
        n.title = "No matches"
        m.list.content = empty
        m.originalContent = empty
        m.list.visible = true
        m.list.setFocus(true)
        m.player.visible = false
    end if
end sub

sub onEpisodeResults()
    m.spinner.visible = false
    ShowStatusMessage("Episodes loaded")
    html = m.episodeTask.message
    selectedContent = m.pendingContent
    if html <> invalid and Len(html) > 0
        episodes = ParseEpisodeList(html, m.baseUrl)
        if episodes <> invalid and episodes.Count() > 0
            m.originalContent = m.list.content
            m.list.content = episodes
            m.isEpisodeList = true
            m.list.jumpToItem(0)
            PrefetchHosts(episodes)
            return
        end if
    else
        LogError("EpisodeTask returned no data")
        ShowHostMessage("Failed to load episodes")
    end if
    if selectedContent <> invalid
        StopVideo()
        m.spinner.visible = true
        m.hostTask.url = selectedContent.url
        m.hostTask.control = "run"
    end if
end sub

sub onHostResults()
    m.spinner.visible = false
    ShowStatusMessage("Hosts loaded")
    html = m.hostTask.message
    content = m.pendingContent
    if html <> invalid and Len(html) > 0
        hosts = ParseHostsFromHtml(html, content.url)
        if hosts <> invalid and hosts.Count() > 0
            content.hosts = hosts
            StartVideo(content)
        else
            LogError("HostTask returned no hosts")
            ShowHostMessage("No hosts found")
        end if
    else
        LogError("HostTask failed to load hosts")
        ShowHostMessage("Failed to load hosts")
    end if
end sub

sub SwitchHost()
    content = m.player.content
    hosts = content.hosts
    if hosts <> invalid and hosts.Count() > 1
        index = (m.currentHostIndex + 1) mod hosts.Count()
        SwitchHostTo(index)
    end if
end sub

sub SwitchHostTo(index as Integer)
    content = m.player.content
    hosts = content.hosts
    if hosts <> invalid and index >= 0 and index < hosts.Count()
        m.currentHostIndex = index
        hostObj = hosts[index]
        content.url = hostObj.url
        content.streamformat = hostObj.format
        Log("Switching host to " + content.url)
        StartVideo(content, false)
        ShowHostMessage("Switching host " + Str(index + 1) + " of " + Str(hosts.Count()))
    end if
end sub

sub ShowHostList()
    content = m.player.content
    hosts = content.hosts
    if hosts = invalid or hosts.Count() = 0 return
    list = CreateObject("roSGNode", "ContentNode")
    idx = 0
    for each h in hosts
        node = list.CreateChild("ContentNode")
        node.title = "Host " + Str(idx + 1) + " (" + h.format + ")"
        idx = idx + 1
    end for
    m.hostList.content = list
    m.hostList.visible = true
    m.hostList.setFocus(true)
end sub

sub HideHostList()
    m.hostList.visible = false
end sub

sub onHostListSelect()
    idx = m.hostList.itemSelected
    HideHostList()
    SwitchHostTo(idx)
end sub

sub ShowHostMessage(msg as String)
    if m.hostLabel <> invalid
        m.hostLabel.text = msg
        m.hostLabel.visible = true
        if m.hostTimer <> invalid
            m.hostTimer.control = "start"
        end if
    end if
end sub

sub onHostTimerFire()
    if m.hostLabel <> invalid
        m.hostLabel.visible = false
    end if
end sub

sub UpdateStatusOverlay()
    if m.statusLabel = invalid return
    state = "Stopped"
    if m.player.control = "pause" then
        state = "Paused"
    else if m.player.control = "play" or m.player.control = "resume" then
        state = "Playing"
    end if
    hostCount = 1
    hostIndex = m.currentHostIndex + 1
    if m.player.content <> invalid and m.player.content.hosts <> invalid then
        hostCount = m.player.content.hosts.Count()
    end if
    text = state + " - Host " + Str(hostIndex)
    if hostCount > 1 then
        text = text + " of " + Str(hostCount)
    end if
    m.statusLabel.text = text
    m.statusLabel.visible = true
end sub

sub ShowStatusMessage(msg as String)
    if m.statusLabel <> invalid
        m.statusLabel.text = msg
        m.statusLabel.visible = true
    end if
end sub

sub onVideoStateChanged()
    if m.player.state = "error" then
        SwitchHost()
    end if
end sub

'Update poster when list focus changes'
sub onItemFocused()
    index = m.list.itemFocused
    item = m.list.content.getChild(index)
    if item <> invalid and item.hdposterurl <> invalid
        m.poster.uri = item.hdposterurl
        m.poster.visible = true
    end if
end sub

'Retrieve host list from watch page'
function GetHostsForVideo(pageUrl as String) as object
    hosts = []
    xfer = CreateObject("roUrlTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.AddHeader("User-Agent", "Mozilla/5.0")
    xfer.SetUrl(pageUrl)
    html = xfer.GetToString()
    if html <> invalid
        btnRegex = CreateObject("roRegex", "iframe-server-button[^>]*data-link=\"([^\"]+)\"", "ims")
        matches = btnRegex.MatchAll(html)
        for each m in matches
            link = m[1]
            if Left(link,1) = "/" then link = m.baseUrl + link
            hosts.Push(link)
        end for
        if hosts.Count() = 0
            hostRegex = CreateObject("roRegex", "https?://[^\"']+(mp4|m3u8|mpd)", "ims")
            matches = hostRegex.MatchAll(html)
            for each m in matches
                hosts.Push(m[0])
            end for
        end if
    end if
    if hosts.Count() = 0
        hosts.Push(pageUrl)
    end if
    return hosts
end function

function ParseHostsFromHtml(html as String, pageUrl as String) as object
    hosts = []
    if html <> invalid
        btnRegex = CreateObject("roRegex", "iframe-server-button[^>]*data-link=\"([^\"]+)\"", "ims")
        matches = btnRegex.MatchAll(html)
        for each m in matches
            link = m[1]
            if Left(link,1) = "/" then link = m.baseUrl + link
            host = { url: link, format: DetermineFormat(link) }
            hosts.Push(host)
        end for
        if hosts.Count() = 0
            iframeRegex = CreateObject("roRegex", "<iframe[^>]+src=\"([^\"]+)\"", "ims")
            matches = iframeRegex.MatchAll(html)
            for each m in matches
                link = m[1]
                if Left(link,1) = "/" then link = m.baseUrl + link
                host = { url: link, format: DetermineFormat(link) }
                hosts.Push(host)
            end for
        end if
        if hosts.Count() = 0
            sourceRegex = CreateObject("roRegex", "<source[^>]+src=\"([^\"]+)\"", "ims")
            matches = sourceRegex.MatchAll(html)
            for each m in matches
                host = { url: m[1], format: DetermineFormat(m[1]) }
                hosts.Push(host)
            end for
        end if
        if hosts.Count() = 0
            urlVarRegex = CreateObject("roRegex", "['\"](https?://[^'\"]+(mp4|m3u8))['\"]", "ims")
            matches = urlVarRegex.MatchAll(html)
            for each m in matches
                host = { url: m[1], format: DetermineFormat(m[1]) }
                hosts.Push(host)
            end for
        end if
        if hosts.Count() = 0
            hostRegex = CreateObject("roRegex", "https?://[^\"']+(mp4|m3u8|mpd)", "ims")
            matches = hostRegex.MatchAll(html)
            for each m in matches
                host = { url: m[0], format: DetermineFormat(m[0]) }
                hosts.Push(host)
            end for
        end if
    end if
    if hosts.Count() = 0
        hosts.Push({ url: pageUrl, format: DetermineFormat(pageUrl) })
    end if
    return hosts
end function

function DetermineFormat(url as String) as String
    if url = invalid return "mp4"
    lower = LCase(url)
    if right(lower,4) = ".m3u8" then
        return "hls"
    else if right(lower,4) = ".mpd" then
        return "dash"
    else
        return "mp4"
    end if
end function

'Simple helper to fetch text from a URL'
function HttpGet(url as String) as dynamic
    x = CreateObject("roUrlTransfer")
    x.SetCertificatesFile("common:/certs/ca-bundle.crt")
    x.AddHeader("User-Agent", "Mozilla/5.0")
    x.SetUrl(url)
    return x.GetToString()
end function

'Playback helper functions
sub StartVideo(content as Object, resetIndex = true as Boolean)
    if resetIndex then
        m.currentHostIndex = 0
    end if
    if content.hosts <> invalid and content.hosts.Count() > 0 then
        hostObj = content.hosts[m.currentHostIndex]
        content.url = hostObj.url
        content.streamformat = hostObj.format
    else
        content.streamformat = DetermineFormat(content.url)
    end if
    Log("Starting playback: " + content.url)
    m.player.content = content
    if content.hosts <> invalid then
        m.player.content.hosts = content.hosts
    end if
    m.player.visible = true
    m.player.control = "play"
    UpdateStatusOverlay()
end sub

sub PauseVideo()
    m.player.control = "pause"
    UpdateStatusOverlay()
end sub

sub ResumeVideo()
    m.player.control = "resume"
    UpdateStatusOverlay()
end sub

sub StopVideo()
    Log("Stopping playback")
    m.player.control = "stop"
    m.player.visible = false
    UpdateStatusOverlay()
end sub

sub FastForward()
    m.player.trickPlayFactor = 4
end sub

sub Rewind()
    m.player.trickPlayFactor = -4
end sub

sub PauseForMenu()
    m.resumeOnMenuClose = false
    if m.player.visible = true and (m.player.control = "play" or m.player.control = "resume") then
        PauseVideo()
        m.resumeOnMenuClose = true
    end if
end sub

sub ResumeFromMenu()
    if m.resumeOnMenuClose and m.player.control = "pause" then
        ResumeVideo()
    end if
    m.resumeOnMenuClose = false
end sub

sub PrefetchEpisodes(listContent as Object)
    limit = listContent.GetChildCount()
    if limit > 3 then limit = 3
    for i = 0 to limit - 1
        item = listContent.GetChild(i)
        if item.url <> invalid and CacheGet(item.url) = invalid
            t = CreateObject("roSGNode", "EpisodeTask")
            t.url = item.url
            m.prefetchTasks.Push(t)
            t.control = "run"
        end if
    end for
end sub

sub PrefetchHosts(listContent as Object)
    limit = listContent.GetChildCount()
    if limit > 3 then limit = 3
    for i = 0 to limit - 1
        item = listContent.GetChild(i)
        if item.isHeader = true then
            next
        end if
        if item.url <> invalid and CacheGet(item.url) = invalid
            t = CreateObject("roSGNode", "HostTask")
            t.url = item.url
            m.prefetchTasks.Push(t)
            t.control = "run"
        end if
    end for
end sub

'Parse episode links from a watch page'
function ParseEpisodeList(html as String, baseUrl as String) as object
    list = CreateObject("roSGNode", "ContentNode")
    if html = invalid return list
    epRegex = CreateObject("roRegex", "data-season=\"(\d+)\"[^>]*data-episode=\"(\d+)\"[^>]*href=\"([^\"]+)\"[^>]*>[^<]*<span[^>]*>([^<]+)", "ims")
    matches = epRegex.MatchAll(html)
    seasonMap = {}
    for each m in matches
        season = m[1]
        if seasonMap.DoesExist(season) = false then seasonMap[season] = []
        path = m[3]
        if Left(path,1) = "/" then path = baseUrl + path
        episode = {
            title: "Episode " + m[2] + " - " + m[4],
            url: path,
            num: Val(m[2])
        }
        seasonMap[season].Push(episode)
    end for

    seasons = seasonMap.Keys()
    seasons.Sort()
    for each s in seasons
        header = list.CreateChild("ContentNode")
        header.title = "Season " + s
        header.description = "header"
        header.AddField("isHeader", "bool", false)
        header.isHeader = true
        eps = seasonMap[s]
        eps.Sort(function(a as Object, b as Object)
            return a.num < b.num
        end function)
        for each ep in eps
            node = list.CreateChild("ContentNode")
            node.title = ep.title
            node.url = ep.url
            node.description = "mp4"
            node.AddField("hosts", "string", true)
        end for
    end for
    return list
end function
