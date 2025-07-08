' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

'Main Scene Initialization with menu and video.
sub init()
    m.player = m.top.FindNode("Video")
    m.list = m.top.FindNode("MenuList")
    m.searchBox = m.top.FindNode("SearchBox")
    m.searchButton = m.top.FindNode("SearchButton")
    m.poster = m.top.FindNode("Poster")
    m.searchButton.ObserveField("buttonSelected", "onSearchPress")
    m.list.ObserveField("itemFocused", "onItemFocused")
    m.player.visible = false
    m.searchBox.setFocus(true)
    m.itemfocused = 0
    m.baseUrl = "https://hydrahd.sh"
    m.isEpisodeList = false
end sub

'Handle remote control key presses'
function onKeyEvent(key as String, press as Boolean) as boolean
  print key + ":" ; press
  if press
    if key = "options"
      SwitchHost()
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
          m.player.setfocus(true)
        else if m.isEpisodeList
          epContent = m.list.content.getChild(m.list.itemfocused)
          if epContent.description = "header" return true
          m.itemfocused = m.list.itemfocused
          StopVideo()
          hosts = GetHostsForVideo(epContent.url)
          epContent.hosts = hosts
          epContent.url = hosts[0]
          m.currentHostIndex = 0
          StartVideo(epContent)
        else
          m.itemfocused = m.list.itemfocused
          selectedContent = m.list.content.getChild(m.list.itemfocused)
          html = HttpGet(selectedContent.url)
          episodes = ParseEpisodeList(html, m.baseUrl)
          if episodes <> invalid and episodes.Count() > 0
            m.originalContent = m.list.content
            m.list.content = episodes
            m.isEpisodeList = true
            m.list.jumpToItem(0)
          else
            StopVideo()
            hosts = GetHostsForVideo(selectedContent.url)
            selectedContent.hosts = hosts
            selectedContent.url = hosts[0]
            m.currentHostIndex = 0
            StartVideo(selectedContent)
          end if
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
        m.player.setfocus(true)
        return true
      else
        m.list.visible = true
        m.list.setfocus(true)
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
    figureRegex = CreateObject("roRegex", "<figure class=\"figured\">(.*?)</figure>", "ims")
    hrefRegex = CreateObject("roRegex", "href=\"([^\"]+)\"", "ims")
    imgRegex = CreateObject("roRegex", "(?:data-src|src)=\"([^\"]+)\"", "ims")
    titleRegex = CreateObject("roRegex", "<div class=\"title detz\">([^<]+)</div>", "ims")
    listContent = CreateObject("roSGNode", "ContentNode")

    figures = figureRegex.MatchAll(html)
    for each item in figures
        block = item[1]
        hrefMatch = hrefRegex.Match(block)
        imgMatch = imgRegex.Match(block)
        titleMatch = titleRegex.Match(block)
        if hrefMatch.Count() > 0 and imgMatch.Count() > 0 and titleMatch.Count() > 0
            node = listContent.CreateChild("ContentNode")
            path = hrefMatch[1]
            if Left(path,1) = "/" then path = m.baseUrl + path
            node.title = titleMatch[1]
            node.url = path
            node.description = "mp4"
            node.hdposterurl = imgMatch[1]
            node.AddField("hosts", "string", true)
            node.hosts = [ path ]
        end if
    end for

    m.list.content = listContent
    m.originalContent = listContent
    m.list.visible = true
    m.list.setFocus(true)
    m.player.visible = false
end sub

sub onSearchPress()
    query = m.searchBox.text
    SearchVideos(query)
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

sub SwitchHost()
    content = m.player.content
    hosts = content.hosts
    if hosts <> invalid and hosts.Count() > 1
        m.currentHostIndex = (m.currentHostIndex + 1) mod hosts.Count()
        content.url = hosts[m.currentHostIndex]
        content.streamformat = DetermineFormat(content.url)
        StartVideo(content)
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
        hostRegex = CreateObject("roRegex", "https?://[^\"']+(mp4|m3u8)", "ims")
        matches = hostRegex.MatchAll(html)
        for each m in matches
            hosts.Push(m[0])
        end for
    end if
    if hosts.Count() = 0
        hosts.Push(pageUrl)
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
sub StartVideo(content as Object)
    content.streamformat = DetermineFormat(content.url)
    m.player.content = content
    m.player.visible = true
    m.player.control = "play"
end sub

sub PauseVideo()
    m.player.control = "pause"
end sub

sub ResumeVideo()
    m.player.control = "resume"
end sub

sub StopVideo()
    m.player.control = "stop"
    m.player.visible = false
end sub

sub FastForward()
    m.player.trickPlayFactor = 4
end sub

sub Rewind()
    m.player.trickPlayFactor = -4
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
