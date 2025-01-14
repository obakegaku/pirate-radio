local prereqs = {}

function prereqs.install()
    local toinstall=""
    local s=util.os_capture("which ogg123")
    print(s)
    if s=="" then 
        print("installing vorbis-tools...")
        toinstall=toinstall.."vorbis-tools "
    end
    s=util.os_capture("which ffmpeg")
    if s=="" then 
        print("installing ffmpeg...")
        toinstall=toinstall.."ffmpeg "
    end
    s=util.os_capture("which curl")
    if s=="" then 
        print("installing curl...")
        toinstall=toinstall.."curl "
    end
    s=util.os_capture("which espeak")
    if s=="" then 
        print("installing espeak...")
        toinstall=toinstall.."espeak "
    end
    if toinstall~="" then 
        print("installing pre-requisites")
        print("sudo apt install -y "..toinstall)
        print(util.os_capture("sudo apt install -y "..toinstall))
    end
end

return prereqs
