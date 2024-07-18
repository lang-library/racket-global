# Overscan

by [Mark Wunsch](https://www.markwunsch.com/)
<[mark@markwunsch.com](mailto:mark@markwunsch.com)>

Overscan is a [live coding
environment](https://en.wikipedia.org/wiki/Live_coding) for live
streaming video.

> Follow Overscan on Twitter
> [@overscan\_lang](https://twitter.com/overscan_lang).

> For examples of other live coding environments, see [Sonic
> Pi](http://sonic-pi.net) or [Extempore](http://extempore.moso.com.au).



The `overscan` DSL can be used to quickly produce a video stream from a
number of video and audio sources, send that stream to a video sink
\(e.g. [Twitch](http://twitch.tv)), and manipulate that stream
on-the-fly.

To see Overscan in action, [watch this video from !!con
2018](https://youtu.be/2aOqaE6oByA) where I demo the live-streaming
capabilities. The code powering that broadcast is [available
online](https://gist.github.com/mwunsch/01f52fc8a3377c7016395db3e630e3e0).
[Overscan’s logo is itself generated with
Overscan.](https://github.com/mwunsch/overscan/blob/master/overscan/scribblings/examples/logo.rkt)

 #lang overscan package: [overscan](https://pkgs.racket-lang.org/package/overscan)

The Overscan collection is built on top of two additional collections
provided by this package: `gstreamer`, a library and interface to the
[GStreamer](https://gstreamer.freedesktop.org/) multimedia framework,
and `ffi/unsafe/introspection`, a module for creating a Foreign Function
Interface built on [GObject
Introspection](https://wiki.gnome.org/Projects/GObjectIntrospection)
bindings.

    1 Getting Started              
      1.1 Installation             
      1.2 Basic Usage              
                                   
    2 Broadcasting                 
      2.1 Twitch                   
      2.2 macOS                    
      2.3 Drawing                  
                                   
    3 GStreamer                    
      3.1 Using GStreamer          
      3.2 `element%`               
        3.2.1 `element-factory%`   
        3.2.2 Events               
        3.2.3 Contexts             
      3.3 `bin%`                   
        3.3.1 `pipeline%`          
      3.4 `bus%`                   
        3.4.1 Messages             
      3.5 `pad%`                   
        3.5.1 `ghost-pad%`         
        3.5.2 Pad Templates        
      3.6 `clock%`                 
      3.7 `device%`                
        3.7.1 `device-monitor%`    
      3.8 Capabilities             
      3.9 Buffers                  
        3.9.1 Memory               
        3.9.2 Samples              
      3.10 Common Elements         
        3.10.1 Source Elements     
          3.10.1.1 `videotestsrc`  
          3.10.1.2 `audiotestsrc`  
        3.10.2 Filter-like Elements
          3.10.2.1 `capsfilter`    
          3.10.2.2 `videomixer`    
          3.10.2.3 `tee`           
          3.10.2.4 `videoscale`    
          3.10.2.5 `videobox`      
        3.10.3 Sink Elements       
          3.10.3.1 `rtmpsink`      
          3.10.3.2 `filesink`      
          3.10.3.3 `appsink%`      
      3.11 Base Support            
                                   
    4 GObject Introspection        
      4.1 Basic Usage              
      4.2 GIRepository             
      4.3 GIBaseInfo               
      4.4 GObjects                 

## 1. Getting Started

### 1.1. Installation

Install Overscan following the instructions at \[missing\]:

  `raco pkg install git://github.com:mwunsch/overscan`

Overscan requires the GStreamer and GObject Introspection libraries to
be installed, along with a number of GStreamer plugins. Several of these
plugins are platform-specific e.g. plugins for accessing camera and
audio sources. Overscan, still in its infancy, is currently ​_only_​
configured to work on a Mac. Overscan has been tested on macOS Sierra
and Racket v6.12. The requirements are assumed to be installed via
[Homebrew](https://brew.sh).

  `brew install gstreamer`

This will install the core GStreamer framework, along with GObject
Introspection libraries as a dependency. Overscan has been tested with
GStreamer version 1.14.0.

From here, you have to install the different [GStreamer plug-in
modules](https://gstreamer.freedesktop.org/documentation/splitup.html)
and some of the dependencies Overscan relies on. Don’t let the naming
conventions of these plugin packs confuse you — the `gst-plugins-bad`
package isn’t ​_bad_​ per say; it won’t harm you or your machine. It’s
​_bad_​ because it doesn’t conform to some of the standards and
expectations of the core GStreamer codebase (i.e. it isn’t well
documented or doesn’t include tests).

  `brew install gst-plugins-base --with-pango`

When installing the base plugins, be sure to include
[Pango](http://www.pango.org), a text layout library used by GTK+.
Overscan uses this for working with text overlays while streaming.

  `brew install gst-plugins-good --with-aalib --with-libvpx`

[AAlib](http://aa-project.sourceforge.net/aalib/) is a library for
converting still and moving images to ASCII art. Not necessary, but
cool.

  `brew install gst-plugins-bad --with-rtmpdump --with-fdk-aac`

[RTMPDump](https://rtmpdump.mplayerhq.hu) is a toolkit for RTMP streams.
[Fraunhofer FDK AAC](https://en.wikipedia.org/wiki/Fraunhofer_FDK_AAC)
is an encoder for AAC audio.

  `brew install gst-plugins-ugly --with-x264`

[x264](http://www.videolan.org/developers/x264.html) is a library for
encoding video streams into the H.264/MPEG-4 AVC format.

With these dependencies in place and a running Racket implementation,
you are now ready to begin broadcasting. Personally, I have installed
Racket with `brew cask install racket`

### 1.2. Basic Usage

The "Hello, world" of Overscan is a test broadcast:

```racket
#lang overscan                    
                                  
(broadcast (videotestsrc)         
           (audiotestsrc)         
           (filesink "/dev/null"))
```

This code will broadcast SMTPE color bars and a 440 Hz tone and write
the resulting stream out to `/dev/null`. Additionally, a preview window
will appear to display the video source, and the tone will play over
your default audio output.

The core concept of Overscan revolves around the broadcast. To stop this
broadcast you would call:

```racket
#lang overscan
              
(stop)        
```

The three arguments to `broadcast` are GStreamer elements. The first is
a source element for generating a video signal (e.g. a `videotestsrc`).
The second, a source for generating audio (e.g. an `audiotestsrc`). A
GStreamer pipeline is created to encode and mux these two sources and
then send them on to the third and final argument, a sink element that
accepts an flv container stream (e.g. a `rtmpsink`). By abstracting away
the details of GStreamer pipeline construction, Overscan allows you to
focus on the basic building blocks of live streaming.

## 2. Broadcasting

A _broadcast_ is a global pipeline that can be controlled through the
Overscan DSL, and provides a global event bus.

```racket
(make-broadcast video-source                
                audio-source                
                flv-sink                    
                #:name name                 
                #:preview video-preview     
                #:monitor audio-monitor     
                #:h264-encoder h264-encoder 
                #:aac-encoder aac-encoder)  
 -> (or/c (is-a?/c pipeline%) #f)           
  video-source : (is-a?/c element%)         
  audio-source : (is-a?/c element%)         
  flv-sink : (is-a?/c element%)             
  name : (or/c string? false/c)             
  video-preview : (is-a?/c element%)        
  audio-monitor : (is-a?/c element%)        
  h264-encoder : (is-a?/c element%)         
  aac-encoder : (is-a?/c element%)          
```

Create a pipeline that encodes a `video-source` into h264 with
`h264-encoder`, an `audio-source` into aac with `aac-encoder`, muxes
them together into an flv, and then sends that final flv to the
`flv-sink`.

```racket
(broadcast [video-source                                      
            audio-source                                      
            flv-sink]                                         
            #:name name                                       
            #:preview video-preview                           
            #:monitor audio-monitor                           
            #:h264-encoder h264-encoder                       
            #:aac-encoder aac-encoder)  -> (is-a?/c pipeline%)
  video-source : (is-a?/c element%) = (videotestsrc)          
  audio-source : (is-a?/c element%) = (audiotestsrc)          
  flv-sink : (is-a?/c element%)                               
           = (filesink (make-temporary-file))                 
  name : (or/c string? false/c)                               
  video-preview : (is-a?/c element%)                          
  audio-monitor : (is-a?/c element%)                          
  h264-encoder : (is-a?/c element%)                           
  aac-encoder : (is-a?/c element%)                            
```

Like `make-broadcast`, this procedure creates a pipeline, but will then
call `start` to promote it to the current broadcast.

```racket
(get-current-broadcast) -> (is-a?/c pipeline%)
```

Gets the current broadcast or raises an error if there is none.

```racket
(start pipeline) -> thread?     
  pipeline : (is-a?/c pipeline%)
```

Transforms the given `pipeline` into the current broadcast by creating
an event listener on its bus and setting its state to `'playing`. The
returned thread is the listener polling the pipeline’s bus.

```racket
(on-air?) -> boolean?
```

Returns `#t` if there is a current broadcast, `#f` otherwise.

```racket
(stop [#:timeout timeout])                         
 -> (one-of/c 'failure 'success 'async 'no-preroll)
  timeout : exact-nonnegative-integer? = 5         
```

Stops the current broadcast by sending an EOS event. If the state of the
pipeline cannot be changed within `timeout` seconds, an error will be
raised.

```racket
(kill-broadcast) -> void?
```

Stops the current broadcast without waiting for a downstream EOS.

```racket
(add-listener listener) -> exact-nonnegative-integer?
  listener : (-> message? (is-a?/c pipeline%) any)   
```

Adds `listener` to the broadcast’s event bus, and returns an identifier
that can be used with `remove-listener`. A separate thread of execution
will call the `listener` whenever a message appears on the bus.

```racket
(remove-listener id) -> void?    
  id : exact-nonnegative-integer?
```

Removes the listener with `id` from the event bus.

```racket
(graphviz path [pipeline]) -> any                         
  path : path-string?                                     
  pipeline : (is-a?/c pipeline%) = (get-current-broadcast)
```

Writes a graphviz dot file to `path` diagramming the `pipeline`.

```racket
overscan-logger : logger?
```

A logger with a topic called `'Overscan`. Used by Overscan’s event bus
to log messages.

### 2.1. Twitch

```racket
 (require overscan/twitch) package: [overscan](https://pkgs.racket-lang.org/package/overscan)
```

[Twitch.tv](https://www.twitch.tv/) is a live streaming community. To
broadcast to Twitch, get a stream key from the dashboard settings and
use it as a parameter to `twitch-sink` with `twitch-stream-key`.

```racket
(twitch-stream-key) -> string?  
(twitch-stream-key key) -> void?
  key : string?                 
 = (getenv "TWITCH_STREAM_KEY") 
```

A parameter that defines the current stream key for broadcasting to
Twitch.tv.

```racket
(twitch-sink [#:test bandwidth-test?]) -> rtmpsink?
  bandwidth-test? : boolean? = #f                  
```

Create a rtmpsink set up to broadcast upstream data to Twitch.tv. If
`bandwidth-test?` is `#t`, the stream will be configured to run a test,
and won’t be broadcast live. This procedure can be parameterized with
`twitch-stream-key`.

### 2.2. macOS

```racket
 (require overscan/macos) package: [overscan](https://pkgs.racket-lang.org/package/overscan)
```

Overscan was developed primarily on a computer running macOS. This
module provides special affordances for working with Apple hardware and
frameworks.

Putting all the pieces together, to broadcast a camera and a microphone
to Twitch, preview the video, and monitor the audio, you would call:

```racket
#lang overscan                          
(require overscan/macos)                
                                        
(call-atomically-in-run-loop (λ ()      
  (broadcast (camera 0)                 
             (audio 0)                  
             (twitch-sink)              
             #:preview (osxvideosink)   
             #:monitor (osxaudiosink))))
```

```racket
audio-sources : (vectorof (is-a?/c device%))
```

A vector of input audio devices available.

```racket
camera-sources : (vectorof (-> (is-a?/c element%)))
```

A vector of factory procedures for creating elements that correspond
with the camera devices available.

```racket
screen-sources : (vectorof (-> (is-a?/c element%)))
```

A vector of factory procedures for creating elements that correspond
with the screen capture devices available.

```racket
(audio pos) -> (is-a?/c element%) 
  pos : exact-nonnegative-integer?
```

Finds the audio device in slot `pos` of `audio-sources` and creates a
source element corresponding to it.

```racket
(camera pos) -> (is-a?/c element%)
  pos : exact-nonnegative-integer?
```

Finds the camera device in slot `pos` of `camera-sources` and creates a
source element corresponding to it.

```racket
(screen  pos                                             
        [#:capture-cursor cursor?                        
         #:capture-clicks clicks?]) -> (is-a?/c element%)
  pos : exact-nonnegative-integer?                       
  cursor? : boolean? = #f                                
  clicks? : boolean? = #f                                
```

Finds the screen capture device in slot `pos` of `screen-sources` and
creates a source element corresponding to it. When `cursor?` or
`clicks?` are `#t`, the element will track the cursor or register clicks
respectively.

```racket
(osxvideosink [name]) -> (element/c "osxvideosink")
  name : (or/c string? #f) = #f                    
```

Creates an element for rendering input into a macOS window. Special care
needs to be taken to make sure that the Racket runtime plays nicely with
this window. See `call-atomically-in-run-loop`.

```racket
(osxaudiosink [name]) -> (element/c "osxaudiosink")
  name : (or/c string? #f) = #f                    
```

Creates an element for rendering audio samples through a macOS audio
output device.

```racket
(call-atomically-in-run-loop thunk) -> any
  thunk : (-> any)                        
```

Because of the idiosyncrasies of Racket, GStreamer, and Cocoa working
together in concert, wrap the state change of a pipeline that includes a
`osxvideosink` in `thunk` and call with this procedure, otherwise the
program will crash. I don’t fully understand the Cocoa happening
underneath the hood, but a good rule of thumb is that if you have a
`broadcast` that includes `osxvideosink`, wrap it in this procedure
before calling it.

### 2.3. Drawing

```racket
 (require overscan/draw) package: [overscan](https://pkgs.racket-lang.org/package/overscan)
```

```racket
(make-drawable  element                                      
               [#:width width                                
                #:height height]) -> (or/c (is-a?/c bin%) #f)
                                     (is-a?/c bitmap-dc%)    
  element : (is-a?/c element%)                               
  width : exact-nonnegative-integer? = 1280                  
  height : exact-nonnegative-integer? = 720                  
```

Creates a means to draw on top of `element` using \[missing\]. This
procedure creates a drawing surface of `width` by `height` dimensions
that overlays `element`. Two values are returned: a bin, or `#f` if an
overlay could not be created, and a `bitmap-dc%` object for drawing
operations.

## 3. GStreamer

[GStreamer](https://gstreamer.freedesktop.org) is an open source
framework for creating streaming media applications. More precisely it
is “a library for constructing graphs of media-handling components.”
GStreamer is at the core of the multimedia capabilities of Overscan.
GStreamer is written in the C programming language with the GLib Object
model. This module, included in the Overscan package, provides Racket
bindings to GStreamer; designed to provide support for building media
pipelines in conventional, idiomatic Racket without worrying about the
peculiarities of C.

```racket
 (require gstreamer) package: [overscan](https://pkgs.racket-lang.org/package/overscan)
```

    3.1 Using GStreamer          
    3.2 `element%`               
      3.2.1 `element-factory%`   
      3.2.2 Events               
      3.2.3 Contexts             
    3.3 `bin%`                   
      3.3.1 `pipeline%`          
    3.4 `bus%`                   
      3.4.1 Messages             
    3.5 `pad%`                   
      3.5.1 `ghost-pad%`         
      3.5.2 Pad Templates        
    3.6 `clock%`                 
    3.7 `device%`                
      3.7.1 `device-monitor%`    
    3.8 Capabilities             
    3.9 Buffers                  
      3.9.1 Memory               
      3.9.2 Samples              
    3.10 Common Elements         
      3.10.1 Source Elements     
        3.10.1.1 `videotestsrc`  
        3.10.1.2 `audiotestsrc`  
      3.10.2 Filter-like Elements
        3.10.2.1 `capsfilter`    
        3.10.2.2 `videomixer`    
        3.10.2.3 `tee`           
        3.10.2.4 `videoscale`    
        3.10.2.5 `videobox`      
      3.10.3 Sink Elements       
        3.10.3.1 `rtmpsink`      
        3.10.3.2 `filesink`      
        3.10.3.3 `appsink%`      
    3.11 Base Support            

### 3.1. Using GStreamer

GStreamer must be initialized before using it. Initialization loads the
GStreamer libraries and plug-ins.

```racket
(require gstreamer)                       
                                          
(unless (gst-initialized?)                
  (if (gst-initialize)                    
      (displayln (gst-version-string))    
      (error "Could not load GStreamer")))
```

This initializes GStreamer if it hasn’t already been loaded, and prints
its version, or raises an error if GStreamer could not be initialized.

From here, a GStreamer pipeline is constructed by linking together
elements. Create an element by using an element factory to make
elements.

```racket
(define test-pattern                     
  (element-factory%-make "videotestsrc"))
                                         
(define preview                          
  (element-factory%-make "osxvideosink"))
                                         
(define my-pipeline                      
  (pipeline%-compose "my-pipeline"       
                     test-pattern        
                     preview))           
```

This code creates two elements: a source that generates test video data
and a native macOS video sink. It then composes a pipeline by linking
those two elements together. Every GStreamer application needs a
pipeline and `pipeline%-compose` is a convenient mechanism for quickly
creating them.

From here the pipeline can be played by setting its state:

`(send` `my-pipeline` `set-state` `'playing)`

This will draw a new window where a test video signal of [SMPTE color
bars](https://en.wikipedia.org/wiki/SMPTE_color_bars) will be displayed.

Shut down the pipeline by setting its state again:

`(send` `my-pipeline` `set-state` `'null)`

A quick way to create a pipeline is by using `parse/launch` to parse a
pipeline description into an element.

```racket
(define trailer-uri                                                                              
  "http://movietrailers.apple.com/movies/marvel/thor-ragnarok/thor-ragnarok-trailer-1_h720p.mov")
                                                                                                 
(define movie-trailer                                                                            
  (parse/launch (format "playbin uri=~a" trailer-uri)))                                          
                                                                                                 
(send movie-trailer play!)                                                                       
```

A _playbin_ element is used to quickly play media from a URI. In
addition to `parse/launch`, the gstreamer module provides a number of
utilities and helpers for working with Common Elements for building
basic pipelines.

```racket
element% : class?        
  superclass: gst-object%
```

The basic building block for any GStreamer media pipeline. _Elements_
are like a black box: something goes in, and something else will come
out the other side. For example, a ​_decoder_​ element would take in
encoded data and would output decoded data. A ​_muxer_​ element would
take in several different media streams and combine them into one.
Elements are linked via pads.

```racket
(send an-element add-pad pad) -> boolean?
  pad : (is-a?/c pad%)                   
```



Adds `pad` to `an-element`. Returns `#t` if the pad could be added, `#f`
otherwise. This method can fail when a pad with the same name already
existed or `pad` already had another parent.

```racket
(send an-element get-compatible-pad  pad    
                                    [caps]) 
 -> (or/c (is-a?/c pad%) #f)                
  pad : (is-a?/c pad%)                      
  caps : (or/c caps? #f) = #f               
```



Look for an unlinked pad to which `pad` can link. When `caps` are
present, they are used as a filter for the link. Returns a `pad%` to
which a link could be made, or `#f` if one cannot be found.

```racket
(send an-element get-compatible-pad-template compattempl)
 -> (or/c pad-template? #f)                              
  compattempl : pad-template?                            
```



Retrieves a pad template from `an-element` that is compatible with
`compattempl`. Pads from compatible templates can be linked together.

```racket
(send an-element get-request-pad name)
 -> (or/c (is-a?/c pad%) #f)          
  name : string?                      
```



Retrieves a pad from `an-element` by name. This version only retrieves
request pads. Returns `#f` if a pad could not be found.

```racket
(send an-element get-static-pad name)
 -> (or/c (is-a?/c pad%) #f)         
  name : string?                     
```



Retrieves a pad from `an-element` by name. This version only retrieves
already-existing (i.e. ​_static_​) pads. Returns `#f` if a pad could not
be found.

```racket
(send an-element link dest) -> boolean?
  dest : (is-a?/c element%)            
```



Links `an-element` to `dest` in that direction, looking for existing
pads that aren’t yet linked or requesting new pads if necessary. Returns
`#t` if the elements could be linked, `#f` otherwise.

```racket
(send an-element unlink dest) -> void?
  dest : (is-a?/c element%)           
```



Unlinks all source pads of `an-element` with all sink pads of the `dest`
element to which they are linked.

```racket
(send an-element link-many element ...+) -> boolean?
  element : (is-a?/c element%)                      
```



Chains together a series of elements, using `link`. The elements must
share a common bin parent.

```racket
(send an-element link-pads srcpadname              
                           dest                    
                           destpadname) -> boolean?
  srcpadname : (or/c string? #f)                   
  dest : (is-a?/c element%)                        
  destpadname : (or/c string? #f)                  
```



Links the two named pads of `an-element` and `dest`. If both elements
have different parents, the link fails. Both `srcpadname` and
`destpadname` could be `#f`, in which acase any pad will be selected.
Returns `#t` if the pads could be linked, `#f` otherwise.

```racket
(send an-element link-pads-filtered srcpadname             
                                    dest                   
                                    destpadname            
                                    filter)     -> boolean?
  srcpadname : (or/c string? #f)                           
  dest : (is-a?/c element%)                                
  destpadname : (or/c string? #f)                          
  filter : (or/c caps? #f)                                 
```



Equivalent to `link-pads`, but if `filter` is present and not `#f`, the
link will be constrained by the specified set of caps.

```racket
(send an-element link-filtered dest filter) -> boolean?
  dest : (is-a?/c element%)                            
  filter : (or/c caps? #f)                             
```



Equivalent to `link`, but if `filter` is present and not `#f`, the link
will be constrained by the specified set of caps.

```racket
(send an-element set-context context) -> void?
  context : context?                          
```



Sets the context of `an-element` to `context`.

```racket
(send an-element get-context type) -> (or/c context? #f)
  type : string?                                        
```



Gets the context with the `type` from `an-element` or `#f` one is not
present.

```racket
(send an-element get-contexts) -> (listof context?)
```



Gets the contexts set on `an-element`.

```racket
(send an-element get-factory) -> (is-a?/c element-factory%)
```



Retrieves the factory that was used to create `an-element`.

```racket
(send an-element set-state state)                               
 -> (one-of/c 'failure 'success 'async 'no-preroll)             
  state : (one-of/c 'void-pending 'null 'ready 'paused 'playing)
```



Sets the state of `an-element`. If the method returns `'async`, the
element will perform the remainder of the state change asynchronously in
another thread, in which case an application can use `get-state` to
await the completion of the state change.

```racket
(send an-element get-state [timeout])                     
 -> (one-of/c 'failure 'success 'async 'no-preroll)       
    (one-of/c 'void-pending 'null 'ready 'paused 'playing)
    (one-of/c 'void-pending 'null 'ready 'paused 'playing)
  timeout : clock-time? = clock-time-none                 
```



Gets the state of `an-element`. For elements that performed an `'async`
state change as a result of `set-state`, this method call will block up
to the specified `timeout` for the state change to complete.

This method returns three values.

The first returned value is the result of most recent state change, i.e.
`'success` if the element has no more pending state and the last state
change succeeded, `'async` if the element is still performing a state
change, `'no-preroll` if the element successfully changed its state but
is not able to provide data yet, or `'failure` if the last state change
failed.

The second return value is the current state of the element.

The third return value is the pending state of the element, i.e. what
the next state will be when the result of the state change is `'async`.

```racket
(send an-element post-message message) -> boolean?
  message : message?                              
```



Posts `message` on `an-element`’s bus. Returns `#t` if the message was
successfully posted, `#f` otherwise.

```racket
(send an-element send-event event) -> boolean?
  event : event?                              
```



Sends an event to `an-element`. Returns `#t` if the event was handled,
`#f` otherwise.

```racket
(send an-element play!)                            
 -> (one-of/c 'failure 'success 'async 'no-preroll)
```



Shorthand equivalent to calling `set-state` on `an-element` with
`'playing`.

```racket
(send an-element pause!)                           
 -> (one-of/c 'failure 'success 'async 'no-preroll)
```



Shorthand equivalent to calling `set-state` on `an-element` with
`'paused`.

```racket
(send an-element stop!)                            
 -> (one-of/c 'failure 'success 'async 'no-preroll)
```



Shorthand equivalent to calling `set-state` on `an-element` with
`'null`.

```racket
(element/c factoryname) -> flat-contract?
  factoryname : string?                  
```

Accepts a string `factoryname` and returns a flat contract that
recognizes elements created by a factory of that name.

```racket
(parse/launch description) -> (or/c (is-a?/c element%) #f)
  description : string?                                   
```

Create a new element based on [command line
syntax](https://gstreamer.freedesktop.org/documentation/tools/gst-launch.html#pipeline-description),
where `description` is a command line describing a pipeline. Returns
`#f` if an element could not be created.


```racket
element-factory% : class?
  superclass: gst-object%
```

_Element factories_ are used to create instances of `element%`.

```racket
(send an-element-factory create [name]) -> (is-a?/c element%)
  name : (or/c string? #f) = #f                              
```



Creates a new instance of `element%` of the type defined by
`an-element-factory`. It will be given the `name` supplied, or if `name`
is `#f`, a unique name will be created for it.
```racket
(send an-element-factory get-metadata)
 -> (hash/c symbol? any/c)            
```



Returns a `hash` of `an-element-factory` metadata e.g. author,
description, etc.


```racket
(element-factory%-find name)            
 -> (or/c (is-a?/c element-factory%) #f)
  name : string?                        
```

Search for an element factory of `name`. Returns `#f` if the factory
could not be found.

```racket
(element-factory%-make  factoryname           
                       [name                  
                        #:class factory%])    
 -> (or/c (is-a?/c element%) #f)              
  factoryname : string?                       
  name : (or/c string? #f) = #f               
  factory% : (subclass?/c element%) = element%
```

Create a new element of the type defined by the given `factoryname`. The
element’s name will be given the `name` if supplied, otherwise the
element will receive a unique name. The returned element will be an
instance of `factory%` if provided.

Returns `#f` if an element was unable to be created.

#### 3.2.2. Events

An _event_ in GStreamer is a small structure to describe notification
signals that can be passed up and down a pipeline. Events can move both
upstream and downstream, notifying elements of stream states. Send an
event through a pipeline with `send-event`.

```racket
(event? v) -> boolean?
  v : any/c           
```

Returns `#t` if `v` is a GStreamer event, `#f` otherwise.

```racket
(event-type ev)                                                                   
 -> (one-of/c 'unknown 'flush-start 'flush-stop 'stream-start 'caps 'segment      
              'stream-collection 'tag 'buffersize 'sink-message 'stream-group-done
              'eos 'toc 'protection 'segment-done 'gap 'qos 'seek 'navigation     
              'latency 'step 'reconfigure 'toc-select 'select-streams             
              'custom-upstream 'custom-downstream 'custom-downstream-oob          
              'custom-downstream-sticky 'custom-both 'custom-both-oob)            
  ev : event?                                                                     
```

Gets the type of event for `ev`.

```racket
(event-seqnum ev) -> exact-integer?
  ev : event?                      
```

Retrieve the sequence number of `ev`.

Events have ever-incrementing sequence numbers. Sequence numbers are
typically used to indicate that an event corresponds to some other set
of messages or events.

Events and messages share the same sequence number incrementor; two
events or messages will never have the same sequence number unless that
correspondence was made explicitly.

```racket
(make-eos-event) -> event?
```

Create a new _EOS_ (end-of-stream) event.

The EOS event will travel down to the sink elements in the pipeline
which will then post an `eos-message?` on the bus after they have
finished playing any buffered data.

The EOS event itself will not cause any state transitions of the
pipeline.

#### 3.2.3. Contexts

A GStreamer _context_ is a container used to store contexts that can be
shared between multiple elements. Applications will set a context on an
element (or a pipeline) with `set-context`.

```racket
(context? v) -> boolean?
  v : any/c             
```

Returns `#t` if `v` is a context, `#f` otherwise.

```racket
(context-type context) -> string?
  context : context?             
```

Gets the type of `context`, which is just a string that describes what
the context contains.

```racket
(context-has-type? context type) -> boolean?
  context : context?                        
  type : string?                            
```

Returns `#t` if `context` has a context type of `type`, `#f` otherwise.

```racket
(context-persistent? context) -> boolean?
  context : context?                     
```

Returns `#t` if `context` is persistent, that is the context will be
kept by the element even if it reaches a `'null` state. Otherwise
returns `#f`.

```racket
(make-context type key value [persistent?]) -> context?
  type : string?                                       
  key : string?                                        
  value : any/c                                        
  persistent? : boolean? = #f                          
```

Create a context of `type` that maps `key` to `value`.

```racket
(context-ref context key) -> (or/c any/c #f)
  context : context?                        
  key : string?                             
```

Retrieves the value of `context` mapped to `key`, or `#f` if no value is
found.

```racket
bin% : class?         
  superclass: element%
```

A _bin_ is a container element. Elements can be added to a bin. Since a
bin is also itself an element, a bin can be handled in the same way as
any other element. Bins combine a group of linked elements into one
logical element, allowing them to be managed as a group.

```racket
(bin%-new [name]) -> (is-a?/c bin%)
  name : (or/c string? #f) = #f    
```

Creates a new bin with the given `name`, or generates a name if `name`
is `#f`.

```racket
(bin%-compose name element ...+) -> (or/c (is-a?/c bin%) #f)
  name : (or/c string? #f)                                  
  element : (is-a?/c element%)                              
```

Compose a new bin with the given `name` (or a generated name if `name`
is `#f`) by adding the given `element`s, linking them in order, and
creating ghost sink and src ghost pads. Returns `#f` if the elements
could not be added or linked. A convenient mechanism for creating a bin,
adding elements to it, and linking them together in one procedure.

```racket
(send a-bin add element) -> boolean?
  element : (is-a?/c element%)      
```



Adds `element` to `a-bin`. Sets the element’s parent. An element can
only be added to one bin.

If `element`’s pads are linked to other pads, the pads will be unlinked
before the element is added to the bin.

Returns `#t` if `element` could be added, `#f` if `a-bin` does not want
to accept `element`.

```racket
(send a-bin remove element) -> boolean?
  element : (is-a?/c element%)         
```



Removes `element` from `a-bin`, unparenting it in the process. Returns
`#t` if `element` could be removed, `#f` if `a-bin` does not want it
removed.

```racket
(send a-bin get-by-name name) -> (or/c (is-a?/c element%) #f)
  name : string?                                             
```



Gets the element with the given `name` from `a-bin`, recursing into
child bins. Returns `#f` if no element with the given name is found in
the bin.

```racket
(send a-bin add-many element ...+) -> boolean?
  element : (is-a?/c element%)                
```



Adds a series of elements to `a-bin`, equivalent to calling `add` for
each `element`. Returns `#t` if every `element` could be added to
`a-bin`, `#f` otherwise.

```racket
(send a-bin find-unlinked-pad direction)    
 -> (or/c (is-a?/c pad%) #f)                
  direction : (one-of/c 'unknown 'src 'sink)
```



Recursively looks for elements with an unlinked pad of the given
`direction` within `a-bin` and returns an unlinked pad if one is found,
or `#f` otherwise.

```racket
(send a-bin sync-children-states) -> boolean?
```



Synchronizes the state of every child of `a-bin` with the state of
`a-bin`. Returns `#t` if syncing the state was successful for all
children, `#f` otherwise.

```racket
(bin->dot bin [#:details details]) -> string?                                                          
  bin : (is-a?/c bin%)                                                                                 
  details : (one-of/c 'media-type 'caps-details 'non-default-params 'states 'full-params 'all 'verbose)
          = 'all                                                                                       
```

Return a string of DOT grammar for use with graphviz to visualize the
`bin`. Useful for debugging purposes. `details` refines the level of
detail to show in the graph.


```racket
pipeline% : class?
  superclass: bin%
```

A _pipeline_ is a special bin used as a top-level container. It provides
clocking and message bus functionality to the application.

```racket
(send a-pipeline get-bus) -> (is-a?/c bus%)
```



Returns the bus of `a-pipeline`. The bus allows the application to
receive messages.
```racket
(send a-pipeline get-pipeline-clock) -> (is-a?/c clock%)
```



Gets the current clock used by `a-pipeline`.
```racket
(send a-pipeline get-latency) -> clock-time?
```



Gets the latency configured on `a-pipeline`. The latency is the time it
takes for a sample to reach the sink.


```racket
(pipeline%-new [name]) -> (is-a?/c pipeline%)
  name : (or/c string? #f) = #f              
```

Creates a new pipeline with the given `name`, or generates a name if
`name` is `#f`.

```racket
(pipeline%-compose name element ...+)
 -> (or/c (is-a?/c pipeline%) #f)    
  name : (or/c string? #f)           
  element : (is-a?/c element%)       
```

Creates a pipeline by first creating a bin with `bin%-compose` and then
adding that bin as a child of the pipeline. Returns the pipeline or `#f`
if the `bin%-compose` call fails or the bin cannot be added to the
pipeline.

```racket
bus% : class?            
  superclass: gst-object%
```

The _bus_ is responsible for delivering messages in a first-in first-out
way from a pipeline.

```racket
(send a-bus post message) -> boolean?
  message : message?                 
```



Post the `message` on `a-bus`. Returns `#t` if the message could be
posted, otherwise `#f`.

```racket
(send a-bus have-pending?) -> boolean?
```



Check if there are pending messages on `a-bus` that should be handled.

```racket
(send a-bus peek) -> (or/c message? #f)
```



Peek the message on the top of `a-bus`’ queue. The message will remain
on the queue. Returns `#f` if the bus is empty.

```racket
(send a-bus pop) -> (or/c message? #f)
```



Gets a message from `a-bus`, or `#f` if the bus is empty.

```racket
(send a-bus pop-filtered types) -> (or/c message? #f)
  types : message-type/c                             
```



Get a message matching any of the given `types` from `a-bus`. Will
discard all messages on the bus that do not match `types`. Retruns `#f`
if the bus is empty or there are no messages that match `types`.

```racket
(send a-bus timed-pop timeout) -> (or/c message? #f)
  timeout : clock-time?                             
```



Gets a message from `a-bus`, waiting up to the specified `timeout`. If
`timeout` is `clock-time-none`, this method will block until a message
was posted on the bus. Returns `#f` if the bus is empty after the
`timeout` expired.

```racket
(send a-bus timed-pop-filtered timeout                      
                               types)  -> (or/c message? #f)
  timeout : clock-time?                                     
  types : message-type/c                                    
```



Gets a message from `a-bus` whose type matches one of the message types
in `types`, waiting up to the specified `timeout` and discarding any
messages that do not match the mask provided.

If `timeout` is 0, this method behaves like `pop-filtered`. If `timeout`
is `clock-time-none`, this method will block until a matching message
was posted on the bus. Returns `#f` if no matching message was found on
the bus after the `timeout` expired.

```racket
(send a-bus disable-sync-message-emission!) -> void?
```



Instructs GStreamer to stop emitting the `'sync-message` signal for
`a-bus`. See `enable-sync-message-emission!` for more information.

```racket
(send a-bus enable-sync-message-emission!) -> void?
```



Instructs GStreamer to emit the `'sync-message` signal after running
`a-bus`’s sync handler. Use `connect` on `a-bus` to listen for this
signal.

```racket
(send a-bus poll events timeout) -> (or/c message? #f)
  events : message-type/c                             
  timeout : clock-time?                               
```



Poll `a-bus` for messages. Will block while waiting for messages to
come. Specify a maximum time to poll with `timeout`. If `timeout` is
negative, this method will block indefinitely.

GStreamer calls this function “pure evil”. Prefer `timed-pop-filtered`
and `make-bus-channel`.

```racket
(make-bus-channel  bus                                    
                  [filter                                 
                   #:timeout timeout])                    
 -> (evt/c (or/c message? false/c (evt/c exact-integer?)))
  bus : (is-a?/c bus%)                                    
  filter : message-type/c = '(any)                        
  timeout : clock-time? = clock-time-none                 
```

This procedure polls `bus` asynchronously using `timed-pop-filtered`
(the `filter` and `timeout` arguments are forwarded on to that method)
and returns a synchronizable event.

That event is ready for synchronization when a new message is emitted
from the `bus` (in which case the synchronization result is a message),
when the `timeout` has been reached (in which case the synchronization
result will be a message or `#f`), or when the `bus` has flushed and
closed down (in which case the synchronization result is another event
that is always ready for synchronization).


#### 3.4.1. Messages

A _message_ is a small structure representing signals emitted from a
pipeline and passed to the application using the bus. Messages have a
`message-type` useful for taking different actions depending on the
type.

```racket
(message? v) -> boolean?
  v : any/c             
```

Returns `#t` if `v` is a message emitted from a bus, `#f` otherwise.

```racket
(message-type message) -> message-type/c
  message : message?                    
```

Gets the type of `message`.

```racket
(message-seqnum message) -> exact-integer?
  message : message?                      
```

Retrieve the sequence number of `message`.

Messages have ever-incrementing sequence numbers. Sequence numbers are
typically used to indicate that a message corresponds to some other set
of messages or events.

```racket
(message-src message) -> (is-a?/c gst-object%)
  message : message?                          
```

Get the object that posted `message`.

```racket
(message-of-type? message type ...+) -> (or/c message-type/c #f)
  message : message?                                            
  type : symbol?                                                
```

Checks if the type of `message` is one of the given `type`s. Returns
`#f` if the `message-type` of `message` is not one of the given `type`s.

```racket
(eos-message? v) -> boolean?
  v : any/c                 
```

Returns `#t` if `v` is a `message?` and has the `message-type` of
`'eos`, otherwise `#f`.

```racket
(error-message? v) -> boolean?
  v : any/c                   
```

Returns `#t` if `v` is a `message?` and has the `message-type` of
`'error`, otherwise `#f`.

```racket
(fatal-message? v) -> boolean?             
  v : any/c                                
 = (or (eos-message? v) (error-message? v))
```

Returns `#t` if `v` is a `message?` and has a `message-type` indicating
that the pipeline that emitted this message should shut down (either a
`'eos` or `'error` message), otherwise `#f`.

```racket
message-type/c : list-contract?
```

A contract matching a list of allowed message types.

```racket
pad% : class?            
  superclass: gst-object%
```

A `element%` is linked to other elements via _pads_. Pads are the
element’s interface to the outside world. Data streams from one
element’s source pad to another element’s sink pad. The specific type of
media that the element can handle will be exposed by the pad’s
capabilities.

A pad is defined by two properties: its direction and its availability.
A pad direction can be a _source pad_ or a _sink pad_. Elements receive
data on their sink pads and generate data on their source pads.

A pad can have three availabilities: always, sometimes, and on request.

```racket
(send a-pad get-direction) -> (one-of/c 'unknown 'src 'sink)
```



Gets the direction of `a-pad`.

```racket
(send a-pad get-parent-element) -> (is-a?/c element%)
```



Gets the parent element of `a-pad`.

```racket
(send a-pad get-pad-template) -> (or/c pad-template? #f)
```



Gets the template for `a-pad`.

```racket
(send a-pad link sinkpad)                                                                   
 -> (one-of/c 'ok 'wrong-hierarchy 'was-linked 'wrong-direction 'noformat 'nosched 'refused)
  sinkpad : (is-a?/c pad%)                                                                  
```



Links `a-pad` and the `sinkpad`. Returns a result code indicating if the
connection worked or what went wrong.

```racket
(send a-pad link-maybe-ghosting sink) -> boolean?
  sink : (is-a?/c pad%)                          
```



Links `a-pad` to `sink`, creating any ghost pads in between as
necessary. Returns `#t` if the link succeeded, `#f` otherwise.

```racket
(send a-pad unlink sinkpad) -> boolean?
  sinkpad : (is-a?/c pad%)             
```



Unlinks `a-pad` from the `sinkpad`. Returns `#t` if the pads were
unlinked and `#f` if the pads were not linked together.

```racket
(send a-pad linked?) -> boolean
```



Returns `#t` if `a-pad` is linked to another pad, `#f` otherwise.

```racket
(send a-pad can-link? sinkpad) -> boolean?
  sinkpad : (is-a?/c pad%)                
```



Checks if `a-pad` and `sinkpad` are compatible so they can be linked.
Returns `#t` if they can be linked, `#f` otherwise.

```racket
(send a-pad get-allowed-caps) -> (or/c caps? #f)
```



Gets the capabilities of the allowed media types that can flow through
`a-pad` and its peer. Returns `#f` if `a-pad` has no peer.

```racket
(send a-pad get-current-caps) -> caps?
```



Gets the capabilities currently configured on `a-pad`, or `#f` when
`a-pad` has no caps.

```racket
(send a-pad get-pad-template-caps) -> caps?
```



Gets the capabilities for `a-pad`’s template.

```racket
(send a-pad get-peer) -> (or/c (is-a?/c pad%) #f)
```



Gets the peer of `a-pad` or `#f` if there is none.

```racket
(send a-pad has-current-caps?) -> boolean?
```



Returns `#t` if `a-pad` has caps set on it, `#f` otherwise.

```racket
(send a-pad active?) -> boolean?
```



Returns `#t` if `a-pad` is active, `#f` otherwise.

```racket
(send a-pad blocked?) -> boolean?
```



Returns `#t` if `a-pad` is blocked, `#f` otherwise.

```racket
(send a-pad blocking?) -> boolean?
```



Returns `#t` if `a-pad` is blocking downstream links, `#f` otherwise.


```racket
ghost-pad% : class?
  superclass: pad% 
```

A _ghost pad_ acts as a proxy for another pad, and are used when working
with bins. They allow the bin to have sink and/or source pads that link
to the sink/source pads of the child elements.

```racket
(send a-ghost-pad get-target) -> (or/c (is-a?/c pad%) #f)
```



Get the target pad of `a-ghost-pad` or `#f` if no target is set.
```racket
(send a-ghost-pad set-target target) -> boolean?
  target : (is-a?/c pad%)                       
```



Sets the new target of `a-ghost-pad` to `target`. Returns `#t` on
success or `#f` if pads could not be linked.


```racket
(ghost-pad%-new name target) -> (or/c (is-a?/c ghost-pad%) #f)
  name : (or/c string? #f)                                    
  target : (is-a?/c pad%)                                     
```

Create a new ghost pad with `"target"` as the target, or `#f` if there
is an error.

```racket
(ghost-pad%-new-no-target name direction)   
 -> (or/c (is-a?/c ghost-pad%) #f)          
  name : (or/c string? #f)                  
  direction : (one-of/c 'unknown 'src 'sink)
```

Create a new ghost pad without a target with the given `direction`, or
`#f` if there is an error.

#### 3.5.2. Pad Templates

```racket
(pad-template? v) -> boolean?
  v : any/c                  
```

A _pad template_ describes the possible media types a pad can handle.
Returns `#t` if `v` is a pad template, `#f` otherwise.

```racket
(pad-template-caps template) -> caps?
  template : pad-template?           
```

Gets the capabilities of `template`.

```racket
(make-pad-template name                            
                   direction                       
                   presence                        
                   caps)     -> pad-template?      
  name : string?                                   
  direction : (one-of/c 'unknown 'src 'sink)       
  presence : (one-of/c 'always 'sometimes 'request)
  caps : caps?                                     
```

Creates a new pad template with a name and with the given arguments.

```racket
(pad%-new-from-template template [name])
 -> (or/c (is-a?/c pad%) #f)            
  template : pad-template?              
  name : (or/c string? #f) = #f         
```

Creates a new pad from `template` with the given `name`, generating a
unique name if `name` is `#f`. Returns `#f` in case of error.

```racket
clock% : class?          
  superclass: gst-object%
```

GStreamer uses a global clock to synchronize the different parts of a
pipeline. Different clock implementations inherit from `clock%`. The
clock returns a monotonically increasing time with `get-time`. In
GStreamer, time is always expressed in ​_nanoseconds_​.

```racket
(send a-clock get-time) -> clock-time?
```



Gets the current time of `a-clock`. The time is always monotonically
increasing.

```racket
(clock-time? v) -> boolean?
  v : any/c                
```

Returns `#t` if `v` is a number that can represent the time elapsed in a
GStreamer pipeline, `#f` otherwise. All time in GStreamer is expressed
in nanoseconds.

```racket
clock-time-none : clock-time?
```

An undefined clock time. Often seen used as a timeout for procedures
where it implies the procedure should block indefinitely.

```racket
(obtain-system-clock) -> (is-a?/c clock%)
```

Obtain an instance of `clock%` based on the system time.

```racket
(time-as-seconds time) -> exact-integer?
  time : clock-time?                    
```

Convert `time` to seconds.

```racket
(time-as-milliseconds time) -> exact-integer?
  time : clock-time?                         
```

Convert `time` to milliseconds (`1/1000` of a second).

```racket
(time-as-microseconds time) -> exact-integer?
  time : clock-time?                         
```

Convert `time` to microseconds (`1/1000000` of a second).

```racket
(clock-diff s e) -> clock-time?
  s : clock-time?              
  e : clock-time?              
```

Calculate a difference between two clock times.


```racket
device% : class?      
  superclass: gobject%
```

A GStreamer _Device_ represents a hardware device that can serve as a
source or a sink. Each device contains metadata on the device, such as
the caps it handles as well as its ​_class_​: a string representation
that states what the device does. It can also create elements that can
be used in a GStreamer pipeline.

```racket
(send a-device create-element [name]) -> (is-a?/c element%)
  name : (or/c string? #f) = #f                            
```



Create an element with all of the required parameters to use `a-device`.
The element will be named `name` or, if `#f`, a unique name will be
generated.

```racket
(send a-device get-caps) -> caps?
```



Get the caps supported by `a-device`.

```racket
(send a-device get-device-class) -> string?
```



Gets the class of `a-device`; A `"/"` separated list.

```racket
(send a-device get-display-name) -> string?
```



Get the user-friendly name of this `a-device`.

```racket
(send a-device has-classes? classes) -> boolean?
  classes : string?                             
```



Returns `#t` if `a-device` matches all of the given `classes`, `#f`
otherwise.


```racket
device-monitor% : class?
  superclass: gobject%  
```

A _device monitor_ monitors hardware devices. They post messages on
their bus when new devices are available and have been removed, and can
get a list of devices.

```racket
(send a-device-monitor get-bus) -> (is-a?/c bus%)
```



Gets the bus for `a-device-monitor` where messages about device states
are posted.
```racket
(send a-device-monitor add-filter classes                  
                                  caps)   -> exact-integer?
  classes : (or/c string? #f)                              
  caps : (or/c caps? #f)                                   
```



Adds a filter for a device to be monitored. Devices that match `classes`
and `caps` will be probed by `a-device-monitor`. If `classes` is `#f`
any device class will be matched. Similarly, if `caps` is `#f`, any
media type will be matched. This will return the id of the filter, or
`0` if no device is available to match this filter.
```racket
(send a-device-monitor remove-filter filter-id) -> boolean?
  filter-id : exact-integer?                               
```



Removes a filter from `a-device-monitor` using a `filter-id` that was
returned by `add-filter`. Returns `#t` if the `filter-id` was valid,
`#f` otherwise.
```racket
(send a-device-monitor get-devices)
 -> (listof (is-a?/c device%))     
```



Gets a list of devices from `a-device-monitor` that match any of its
filters.


```racket
(device-monitor%-new) -> (is-a?/c device-monitor%)
```

Create a new device monitor.

### 3.8. Capabilities

Capabilities, or _caps_, are a mechanism to describe the data that can
flow or currently flows through a pad. They are a structure describing
media types.

```racket
(caps? v) -> boolean?
  v : any/c          
```

Returns `#t` if `v` is a cap describing media types, `#f` otherwise.

```racket
(string->caps str) -> (or/c caps? #f)
  str : string?                      
```

Convert caps from a string representation. Returns `#f` if caps could
not be converted from `str`.

```racket
(caps->string caps) -> string?
  caps : caps?                
```

Convert `caps` to a string representation.

```racket
(caps-append! caps1 caps2) -> void?
  caps1 : caps?                    
  caps2 : caps?                    
```

Appends the structure contained in `caps2` to `caps1`. The structures in
`caps2` are not copied — they are transferred and `caps1` is mutated.

```racket
(caps-any? caps) -> boolean?
  caps : caps?              
```

Returns `#t` if `caps` represents any media format, `#f` otherwise.

```racket
(caps-empty? caps) -> boolean?
  caps : caps?                
```

Returns `#t` if `caps` represents no media formats, `#f` otherwise.

```racket
(caps-fixed? caps) -> boolean?
  caps : caps?                
```

Returns `#t` if `caps` is fixed, `#f` otherwise. Fixed caps describe
exactly one format.

```racket
(caps=? caps1 caps2) -> boolean?
  caps1 : caps?                 
  caps2 : caps?                 
```

Returns `#t` if `caps1` and `caps2` represent the same set of caps, `#f`
otherwise.

### 3.9. Buffers

_Buffers_ are the basic unit of data transfer of GStreamer. Buffers
contain blocks of memory.

```racket
(buffer? v) -> boolean?
  v : any/c            
```

Returns `#t` if `v` is a buffer containing media data, `#f` otherwise.

#### 3.9.1. Memory

_Memory_ in GStreamer are lightweight objects wrapping a region of
memory. They are used to manage the data within a buffer.

```racket
(memory? v) -> boolean?
  v : any/c            
```

Returns `#t` if `v` is an object referencing a region of memory
containing media data, `#f` otherwise.

#### 3.9.2. Samples

A media _sample_ is a small object associating a buffer with a media
type in the form of caps.

```racket
(sample? v) -> boolean?
  v : any/c            
```

Returns `#t` if `v` is a media sample, `#f` otherwise.

### 3.10. Common Elements

Included in `gstreamer` are helpers and utilities for working with
frequently used elements, including predicates (implemented with
`element/c`) and property getters/setters.

#### 3.10.1. Source Elements

A source element generates data for use by a pipeline. A source element
has a source pad and do not accept data, they only produce it.

Examples of source elements are those that generate video or audio
signal, or those that capture data from a disk or some other input
device.

##### 3.10.1.1. `videotestsrc`

```racket
(videotestsrc [name                               
               #:pattern pattern                  
               #:live? is-live?]) -> videotestsrc?
  name : (or/c string? #f) = #f                   
  pattern : videotest-pattern/c = 'smpte          
  is-live? : boolean? = #t                        
```

Creates a _videotestsrc_ element with the given `name` (or a generated
name if `#f`). A videotestsrc element produces a `pattern` on its src
pad.

```racket
(videotestsrc? v) -> boolean?
  v : any/c                  
```

Returns `#t` if `v` is an element of the `"videotestsrc"` factory, `#f`
otherwise.

```racket
videotest-pattern/c : flat-contract?                        
 = (one-of/c 'smpte 'snow 'black 'white 'red 'green 'blue   
             'checkers-1 'checkers-2 'checkers-4 'checkers-8
             'circular 'blink 'smpte75 'zone-plate 'gamut   
             'chroma-zone-plate 'solid-color 'ball 'smpte100
             'bar 'pinwheel 'spokes 'gradient 'colors)      
```

A contract that accepts a valid pattern for a `videotestsrc`.

```racket
(videotestsrc-pattern element) -> videotest-pattern/c
  element : videotestsrc?                            
```

Returns the test pattern of `element`.

```racket
(set-videotestsrc-pattern! element pattern) -> void?
  element : videotestsrc?                           
  pattern : videotest-pattern/c                     
```

Sets the test pattern of `element`.

```racket
(videotestsrc-live? element) -> boolean?
  element : videotestsrc?               
```

Returns `#t` if `element` is being used as a live source, `#f`
otherwise.

##### 3.10.1.2. `audiotestsrc`

```racket
(audiotestsrc [name #:live? is-live?]) -> audiotestsrc?
  name : (or/c string? #f) = #f                        
  is-live? : boolean? = #t                             
```

Creates a _audiotestsrc_ element with the given `name`.

```racket
(audiotestsrc? v) -> boolean?
  v : any/c                  
```

Returns `#t` if `v` is an element of the `"audiotestsrc"` factory, `#f`
otherwise.

```racket
(audiotestsrc-live? element) -> boolean?
  element : audiotestsrc?               
```

Returns `#t` if `element` is being used as a live source, `#f`
otherwise.

#### 3.10.2. Filter-like Elements

Filters and filter-like elements have both input and output pads, also
called sink and source pads respectively. They operate on data they
receive on their sink pads and provide data on their output pads.

Examples include an h.264 encoder, an mp4 muxer, or a tee element — used
to take a single input and send it to multiple outputs.

##### 3.10.2.1. `capsfilter`

```racket
(capsfilter caps [name]) -> capsfilter?
  caps : caps?                         
  name : (or/c string? #f) = #f        
```

Create a _capsfilter_ element with the given `name` (or use a generated
name if `#f`). A capsfilter element does not modify data but can enforce
limitations on the data passing through it via its `caps` property.

```racket
(capsfilter? v) -> boolean?
  v : any/c                
```

Returns `#t` if `v` is an element of the `"capsfilter"` factory, `#f`
otherwise.

```racket
(capsfilter-caps element) -> caps?
  element : capsfilter?           
```

Returns the possible allowed caps of `element`.

```racket
(set-capsfilter-caps! element caps) -> void?
  element : capsfilter?                     
  caps : caps?                              
```

Sets the allowed caps of `element` to `caps`.

##### 3.10.2.2. `videomixer`

```racket
(videomixer name) -> videomixer?
  name : (or/c string? #f)      
```

Create a _videomixer_ element with the given `name` (or use a generated
name if `#f`). A videomixer element composites/mixes multiple video
streams into one.

```racket
(videomixer? v) -> boolean?
  v : any/c                
```

Returns `t` if `v` is an element of the `"videomixer"` factory, `#f`
otherwise.

```racket
(videomixer-ref mixer pos) -> (or/c (is-a?/c pad%) #f)
  mixer : videomixer?                                 
  pos : exact-nonnegative-integer?                    
```

Gets the pad at `pos` from `mixer`, or `#f` if there is none present.

##### 3.10.2.3. `tee`

```racket
(tee [name]) -> tee?           
  name : (or/c string? #f) = #f
```

Create a _tee_ element with the given `name` (or use a generated name if
`#f`). A tee element is a 1-to-N pipe fitting element, meant for
splitting data to multiple pads.

```racket
(tee? v) -> boolean?
  v : any/c         
```

Returns `#t` if `v` is an element of the `"tee"` factory, `#f`
otherwise.

##### 3.10.2.4. `videoscale`

```racket
(videoscale [name]) -> videoscale?
  name : (or/c string? #f) = #f   
```

```racket
(videoscale? v) -> boolean?
  v : any/c                
```

Returns `#t` if `v` is an element of the `"videoscale"` factory, `#f`
otherwise.

##### 3.10.2.5. `videobox`

```racket
(videobox [name]                            
           #:autocrop? autocrop             
           #:top top                        
           #:bottom bottom                  
           #:left left                      
           #:right right)       -> videobox?
  name : (or/c string? #f) = #f             
  autocrop : boolean?                       
  top : exact-integer?                      
  bottom : exact-integer?                   
  left : exact-integer?                     
  right : exact-integer?                    
```

Create a _videobox_ element with the given `name`. A videobox element
will crop or enlarge the input video stream. The `top`, `bottom`,
`left`, and `right` parameters will crop pixels or add pixels to a
border depending on if the values are positive or negative,
respectively. When `autocrop` is `#t`, caps will determine crop
properties. This element can be used to support letterboxing, mosaic,
and picture-in-picture.

```racket
(videobox? v) -> boolean?
  v : any/c              
```

Returns `#t` if `v` is an element of the `"videobox"` factory, `#f`
otherwise.

#### 3.10.3. Sink Elements

_Sink_ elements are the end points in a media pipeline. They accept data
but do not produce anything. Writing to a disk or video or audio
playback are implemented by sink elements.

##### 3.10.3.1. `rtmpsink`

```racket
(rtmpsink location [name]) -> rtmpsink?
  location : string?                   
  name : (or/c string? #f) = #f        
```

Create a _rtmpsink_ element with the given `name` (or use a generated
name if `#f`) and with `location` as the RTMP URL.

```racket
(rtmpsink? v) -> boolean?
  v : any/c              
```

Returns `#t` if `v` is an element of the `"rtmpsink"` factory, `#f`
otherwise.

```racket
(rtmpsink-location element) -> string?
  element : rtmpsink?                 
```

Returns the RTMP URL of the `element`.

##### 3.10.3.2. `filesink`

```racket
(filesink location [name]) -> filesink?
  location : path-string?              
  name : (or/c string? #f) = #f        
```

Create a _filesink_ element with the given `name` (or use a generated
name) and with `location` as a file path on the local file system.

```racket
(filesink? v) -> boolean?
  v : any/c              
```

Returns `#t` if `v` is an element of the `"filesink"` factory, `#f`
otherwise.

```racket
(filesink-location element) -> path-string?
  element : filesink?                      
```

Returns the file path of the `element`.

##### 3.10.3.3. `appsink%`

```racket
 (require gstreamer/appsink) package: [overscan](https://pkgs.racket-lang.org/package/overscan)
```

An _appsink_ is a sink element that is designed to extract sample data
out of the pipeline into the application.

```racket
appsink% : class?     
  superclass: element%
```

```racket
(send an-appsink eos?) -> boolean?
```

This method is final, so it cannot be overridden.
```racket
(send an-appsink dropping?) -> boolean?
```

This method is final, so it cannot be overridden.
```racket
(send an-appsink get-max-buffers) -> exact-nonnegative-integer?
```

This method is final, so it cannot be overridden.
```racket
(send an-appsink get-caps) -> (or/c caps? #f)
```

This method is final, so it cannot be overridden.
```racket
(send an-appsink set-caps! caps) -> void?
  caps : caps?                           
```

This method is final, so it cannot be overridden.
```racket
(send an-appsink get-eos-evt) -> evt?
```

This method is final, so it cannot be overridden.
```racket
(send an-appsink on-sample sample) -> any?
  sample : sample?                        
```

Refine this method with `augment`.
```racket
(send an-appsink on-eos) -> any?
```

Refine this method with `augment`.

```racket
(make-appsink [name class%]) -> (is-a?/c appsink%)
  name : (or/c string? #f) = #f                   
  class% : (subclass?/c appsink%) = appsink%      
```

Create an appsink element with the name `name` or a generated name if
`#f`. If `class%` is provided and a subclass of `appsink%`, the returned
element will be an instance of `class%`.

### 3.11. Base Support

```racket
(gst-version-string) -> string?
```

This procedure returns a string that is useful for describing this
version of GStreamer to the outside world.

```racket
(gst-version) -> exact-integer?
                 exact-integer?
                 exact-integer?
                 exact-integer?
```

Returns the version numbers of the imported GStreamer library as
_major_, _minor_, _micro_, and _nano_.

```racket
(gst-initialized?) -> boolean?
```

Returns `#t` if GStreamer has been initialized, `#f` otherwise.

```racket
(gst-initialize) -> boolean?
```

Initializes the GStreamer library, loading standard plugins. The
GStreamer library must be initialized before attempting to create any
Elements. Returns `#t` if GStreamer could be initialized, `#f` if it
could not be for some reason.

```racket
gst : gi-repository?
```

The entry point for the GObject Introspection Repository for GStreamer.
Useful for accessing more of the GStreamer C functionality than what is
provided by the module.

```racket
gst-object% : class?  
  superclass: gobject%
  extends: gobject<%> 
```

The base class for nearly all objects within GStreamer. Provides
mechanisms for getting object names and parentage. Typically, objects of
this class should not be instantiated directly; instead factory
functions should be used.

```racket
(send a-gst-object get-name) -> string?
```



Returns the name of `a-gst-object`.
```racket
(send a-gst-object get-parent) -> (or/c gobject? #f)
```



Returns the parent of `a-gst-object` or `#f` if `a-gst-object` has no
parent.
```racket
(send a-gst-object has-as-parent? parent) -> boolean?
  parent : gobject?                                  
```



Returns `#t` if `parent` is the parent of `a-gst-object`, `#f`
otherwise.
```racket
(send a-gst-object get-path-string) -> string?
```



Generates a string describing the path of `a-gst-object` in the object
hierarchy.


## 4. GObject Introspection

GStreamer is the core framework that powers the multimedia capabilities
of Overscan. GStreamer is also a **C** framework, which means that a big
part of Overscan’s codebase is dedicated to the interop between Racket
and C. Racket provides a phenomenal Foreign Interface, but to create
foreign functions for all the relevant portions of GStreamer would be
cumbersome, at best.

Luckily, GStreamer is written with
[GLib](https://wiki.gnome.org/Projects/GLib) and contains [GObject
Introspection](https://wiki.gnome.org/Projects/GObjectIntrospection)
metadata. _GObject Introspection_ (aka _GIR_) is an interface
description layer that allows for a language to read this metadata and
dynamically create bindings for the C library.

The Overscan package provides a module designed to accompany Racket’s
FFI collection. This module brings additional functionality and
\[missing\] for working with introspected C libraries. This module
powers the GStreamer module, but can be used outside of Overscan for
working with other GLib libraries.

```racket
 (require ffi/unsafe/introspection) package: [overscan](https://pkgs.racket-lang.org/package/overscan)
```

### 4.1. Basic Usage

Using GIR will typically go as follows: Introspect a namespace that you
have a typelib for with `introspection`, call that namespace as a
procedure to look up a binding, work with that binding either as a
procedure or some other value (typically a gobject).

In this case of a typical "Hello, world" style example with GStreamer,
that would look like this:

```racket
(define gst (introspection 'Gst))          
(define gst-version (gst 'version_string)) 
(printf "This program is linked against ~a"
        (gst-version))                     
```

This will result in the string `"This program is linked against
GStreamer 1.10.4"` being printed, or whatever version of GStreamer is
available.

In the second line of this program, the `'version_string` symbol is
looked up against the GStreamer typelib and a `gi-function?` is
returned. That can then be called as a procedure, which in this case
takes no arguments.

### 4.2. GIRepository

GIR’s
[`GIRepository`](https://developer.gnome.org/gi/stable/GIRepository.html)
API manages the namespaces provided by the GIR system and type
libraries. Each namespace contains metadata entries that map to C
functionality. In the case of GStreamer, the `'Gst` namespace contains
all of the introspection information used to power that interface.

```racket
(introspection namespace [version]) -> gi-repository?
  namespace : symbol?                                
  version : string? = #f                             
```

Search for the `namespace` typelib in the GObject Introspection
repository search path and load it. If `version` is not specified, the
latest version will be used.

An example for loading the GStreamer namespace:

```racket
> (define gst (introspection 'Gst))
  #<procedure:gi-repository>       
```

This is the only provided mechanism to construct a `gi-repository`.

```racket
(struct gi-repository (namespace version info-hash))
  namespace : symbol?                               
  version : string?                                 
  info-hash : (hash/c symbol? gi-base?)             
```

A struct representing a namespace of an introspected typelib. This
struct is constructed bye calling `introspection`. This struct has the
`prop:procedure` property and is intended to be called as a procedure:

```racket
(repository) -> (hash/c symbol? gi-base?)
(repository name) -> gi-base?            
  name : symbol?                         
```

When called as in the first form, without an argument, the proc will
return a `hash` of all of the known members of the namespace.
When called as the second form, this is the equivalent to
`gi-repository-find-name` with the first argument already set. e.g.
```racket
> (gst 'version)          
  #<procedure:gi-function>
```
This will return an introspected foreign binding to the
[`gst_version()`](https://gstreamer.freedesktop.org/data/doc/gstreamer/head/gstreamer/html/gstreamer-Gst.html#gst-version)
C function, represented as a `gi-function?`.

```racket
(gi-repository-find-name repo name) -> gi-base?
  repo : gi-repository?                        
  name : symbol?                               
```

Find a metadata entry called `name` in the `repo`. These ​_entries_​
form the basis of the foreign interface. This will raise an
`exn:fail:contract` exception if the entry is not a part of the given
namespace.

```racket
(gi-repository->ffi-lib repo) -> ffi-lib?
  repo : gi-repository?                  
```

Lookup the library path of a repository and return a foreign-library
value

```racket
(gir-member/c namespace) -> flat-contract?
  namespace : symbol?                     
```

Accepts a GIR `namespace` and returns a flat contract that recognizes a
symbol within that namespace. Use this to check for whether or not an
entry is a member of a namespace.

```racket
(gi-repository-member/c repo) -> flat-contract?
  repo : gi-repository?                        
```

Equivalent to `gir-member/c` except with a repository struct (as
returned by `introspection`) instead of a namespace.

### 4.3. GIBaseInfo

The
[`GIBaseInfo`](https://developer.gnome.org/gi/stable/gi-GIBaseInfo.html)
C Struct is the base struct for all GIR metadata entries. Whenever you
do some lookup within GIR, what’s returned is an instance of a
descendant from this struct. The `gi-base` struct is the Racket
equivalent, and `introspection` will return entities that inherit from
this base struct.

```racket
(struct gi-base (info))
  info : cpointer?     
```

The common base struct of all GIR metadata entries. Instances of this
struct have the `prop:cpointer` property, and can be used transparently
as `cpointers` to their respective entries. This struct and its
descendants are constructed by looking up a symbol on a `gi-repository`.

When a GIR metadata entry is located it will usually be a subtype of
`gi-base`. Most of those subtypes implement `prop:procedure` and are
designed to be called on return to produce meaningful values.

The typical subtypes are:

```racket
(gi-function arg ...) -> any
  arg : any/c               
```

An introspected C function. Call this as you would any other Racket
procedure. C functions have a tendency to mutate call-by-reference
pointers, and when that is the case calling a `gi-function` returns
multiple values. The first return value is always the return value of
the function.

```racket
(gi-constant) -> any/c
```

Calling a `gi-constant` as a procedure returns its value.

```racket
(gi-struct method-name arg ...) -> any
  method-name : symbol?               
  arg : any/c                         
```

The first argument to a `gi-struct` is the name of a method, with
subsequent arguments passed in to that method call. This procedure form
is mainly used for calling factory style methods, and more useful for
the similar `gi-object`. Usually, you’ll be working with instances of
this type, `gstruct`s.

```racket
(gi-object method-name arg ...) -> any
  method-name : symbol?               
  arg : any/c                         
```

Like `gi-struct`, calling a `gi-object` as a procedure will accept a
method name and subsequent arguments. This is the preferred form for
calling constructors that will return gobjects.

```racket
gi-enum : gi-enum?
```

A `gi-enum` represents an enumeration of values and, unlike other
`gi-base` subtypes, is not represented as a procedure. The main use case
is to transform it into some other Racket representation, i.e. with
`gi-enum->list`.

```racket
(gi-base-name info) -> symbol?
  info : gi-base?             
```

Obtain the name of the `info`.

```racket
(gi-base=? a b) -> boolean?
  a : gi-base?             
  b : gi-base?             
```

Compare two `gi-base`s. Doing pointer comparison or other equality
comparisons does not work. This function compares two entries of the
typelib.

```racket
(gi-function? v) -> boolean?
  v : any/c                 
```

A
[`GIFunctionInfo`](https://developer.gnome.org/gi/stable/gi-GIFunctionInfo.html)
struct inherits from GIBaseInfo and represents a C function. Returns
`#t` if `v` is a Function Info, `#f` otherwise.

```racket
(gi-registered-type? v) -> boolean?
  v : any/c                        
```

A
[`GIRegisteredTypeInfo`](https://developer.gnome.org/gi/stable/gi-GIRegisteredTypeInfo.html)
struct inherits from GIBaseInfo. An entry of this type represents some C
entity with an associated
[GType](https://developer.gnome.org/gobject/stable/gobject-Type-Information.html).
Returns `#t` if `v` is a Registered Type, `#f` otherwise.

```racket
(gi-enum? v) -> boolean?
  v : any/c             
```

A
[`GIEnumInfo`](https://developer.gnome.org/gi/stable/gi-GIEnumInfo.html)
is an introspected entity representing an enumeration. Returns `#t` if
`v` is an Enumeration, `#f` otherwise.

```racket
(gi-bitmask? v) -> boolean?
  v : any/c                
```

Returns `#t` if `v` is a `gi-enum?` but is represented as a bitmask in
C.

```racket
(gi-enum->list enum) -> list?
  enum : gi-enum?            
```

Convert `enum` to a list of symbols, representing the values of the
enumeration.

```racket
(gi-enum->hash enum) -> hash?
  enum : gi-enum?            
```

Convert `enum` to a hash mapping symbols to their numeric value.

```racket
(gi-enum-value/c enum) -> flat-contract?
  enum : gi-enum?                       
```

Accepts a `gi-enum` and returns a flat contract that recognizes its
values.

```racket
(gi-bitmask-value/c enum) -> list-contract?
  enum : gi-bitmask?                       
```

Accepts a bitmask `gi-enum` and returns a contract that recognizes a
list of allowed values.

```racket
(gi-object? v) -> boolean?
  v : any/c               
```

A
[`GIObjectInfo`](https://developer.gnome.org/gi/stable/gi-GIObjectInfo.html)
is an introspected entity representing a GObject. This does not
represent an instance of a GObject, but instead represents a GObject’s
type information (roughly analogous to a "class"). Returns `#t` if `v`
is a GIObjectInfo, `#f` otherwise.

See GObjects for more information about using GObjects from within
Racket.

```racket
(gi-struct? v) -> boolean?
  v : any/c               
```

A `GIStructInfo` is an introspected entity representing a C Struct.
Returns `#t` if `v` is a GIStructInfo, `#f` otherwise.

```racket
(_gi-object obj) -> ctype?
  obj : gi-object?        
```

Constructs a `ctype` for the given `obj`, which is effectively a
`_cpointer` that will dereference into an instance of the `obj`.

```racket
(struct gi-instance (type pointer))
  type : gi-registered-type?       
  pointer : cpointer?              
```

Represents an instance of a GType `type`. This struct and its
descendants have the `prop:cpointer` property, and can be used as a
pointer in FFI calls. Registered type instances can have methods and
fields associated with them.

```racket
(gi-instance-name instance) -> symbol?
  instance : gi-instance?             
```

Returns the name of the type of `instance`.

```racket
(is-gtype? v type) -> boolean?
  v : any/c                   
  type : gi-registered-type?  
```

Returns `#t` if `v` is an instance of `type`, `#f` otherwise. Similar to
`is-a?`.

```racket
(is-gtype?/c type) -> flat-contract?
  type : gi-registered-type?        
```

Accepts a `type` and returns a flat contract that recognizes its
instances.

```racket
(gtype? v) -> boolean?
  v : any/c           
```

Returns `#t` if `v` is a valid GType, `#f` otherwise.

```racket
(gtype-name gtype) -> symbol?
  gtype : gtype?             
```

Gets the unique name that is assigned to `gtype`.

```racket
(struct gstruct gi-instance (type pointer))
  type : gi-struct?                        
  pointer : cpointer?                      
```

Represents an instance of a C Struct. That Struct can have methods and
fields.

### 4.4. GObjects

A _gobject_ instance, like the introspected metadata entries provided by
GIR, is a transparent pointer with additional utilities to be called as
an object within Racket. GObjects behave like Racket objects, with the
exception that they aren’t backed by ​_classes_​ in the `racket/class`
sense, but instead are derived from the introspected metadata.

```racket
(gobject? v) -> boolean?
  v : any/c             
```

Returns `#t` if `v` is an instance of a GObject, `#f` otherwise. You can
call methods, get or set fields, get/set properties, or connect to
signals on a GObject. `gstruct` structs are also GObjects for the
purposes of this predicate, since they behave in similar ways with the
exception of signals and properties.

```racket
(gobject/c type) -> flat-contract?
  type : gi-registered-type?      
```

Accepts a `type` and returns a flat contract that recognizes objects
that instantiate it. Unlike `is-gtype?/c`, this implies `gobject?`.

```racket
(gobject-ptr obj) -> gi-instance?
  obj : gobject?                 
```

Returns the `gi-instance` associated with `obj`.

```racket
(gobject=? obj1 obj2) -> boolean?
  obj1 : gobject?                
  obj2 : gobject?                
```

Compares the values of two GObjects. Two different gobjects can contain
the same reference. This effectively does pointer comparison using
`ptr-equal?`.

```racket
(gobject-gtype obj) -> gtype?
  obj : gobject?             
```

Returns the GType of `obj`.

```racket
(gobject-send obj method-name argument ...) -> any
  obj : gobject?                                  
  method-name : symbol?                           
  argument : any/c                                
```

Calls the method on `obj` whose name matches `method-name`, passing
along all given `argument`s.

```racket
(gobject-get-field field-name obj) -> any
  field-name : symbol?                   
  obj : gobject?                         
```

Extracts the field from `obj` whose name matches `field-name`. Note that
​_fields_​ are distinct from GObject ​_properties_​, which are accessed
with `gobject-get`.

```racket
(gobject-set-field! field-name obj v) -> void?
  field-name : symbol?                        
  obj : gobject?                              
  v : any/c                                   
```

Sets the field from `obj` whose name matches `field-name` to `v`.

```racket
(gobject-responds-to? obj method-name) -> boolean?
  obj : gobject?                                  
  method-name : symbol?                           
```

Produces `#t` if `obj` or its ancestors defines a method with the name
`method-name`, `#f` otherwise.

```racket
(gobject-responds-to?/c method-name) -> flat-contract?
  method-name : symbol?                               
```

Accepts a `method-name` and returns a flat contract that recognizes
objects with a method defined with the given name in it or its
ancestors. Useful for duck-typing.

```racket
(method-names obj) -> (listof symbol?)
  obj : gobject?                      
```

Extracts a list that `obj` recognizes as names of methods it
understands. This list might not be exhaustive.

```racket
(connect  obj                                  
          signal-name                          
          handler                              
         [#:data data                          
          #:cast _user-data]) -> exact-integer?
  obj : gobject?                               
  signal-name : symbol?                        
  handler : procedure?                         
  data : any/c = #f                            
  _user-data : (or/c ctype? gi-object?) = #f   
```

Register a callback `handler` for the
_[signal](https://developer.gnome.org/gobject/stable/signal.html)_
matching the name `signal-name` for the `obj`. The `handler` will
receive three arguments, `obj`, the name of the signal as a string, and
`data`. When both are present, `data` will be cast to `_user-data`
before being passed to the `handler`.

```racket
(gobject-cast pointer obj) -> gobject?
  pointer : cpointer?                 
  obj : gi-object?                    
```

This will cast `pointer` to `(_gi-object obj)`, thereby transforming it
into a gobject.

```racket
(gobject-get obj propname ctype) -> any?                    
  obj : gobject?                                            
  propname : string?                                        
  ctype : (or/c ctype? gi-registered-type? (listof symbol?))
```

Extract the
[property](https://developer.gnome.org/gobject/stable/gobject-properties.html)
from `obj` whose name matches `propname` and can be dereferenced as a
`ctype`.

```racket
(gobject-set! obj propname v [ctype]) -> void?
  obj : gobject?                              
  propname : string?                          
  v : any/c                                   
  ctype : (or/c ctype? (listof symbol?)) = #f 
```

Sets the property of `obj` whose name matches `propname` to `v`. If
`ctype` is a `(listof symbol?)`, `v` is assumed to be a symbol in that
list, used for representing `_enum`s. If no `ctype` is provided, one is
inferred based on `v`.

```racket
(gobject-with-properties obj properties) -> gobject?
  obj : gobject?                                    
  properties : (hash/c symbol? any/c)               
```

Sets a group of properties on `obj` based on a hash and returns `obj`.
Note that you cannot explicitly set the `ctype` of the properties with
this form.

```racket
(make-gobject-property-procedures propname                  
                                  ctype)                    
 -> (-> gobject? any)                                       
    (-> gobject? any/c void?)                               
  propname : string?                                        
  ctype : (or/c ctype? gi-registered-type? (listof symbol?))
```

Accepts a `propname` and a `ctype` and creates and returns a
_gobject-property-accessor_ and a _gobject-property-mutator_. The
accessor accepts a gobject and returns the value of the property with
the name matching `propname` via `gobject-get`. The mutator accepts a
gobject and a value and mutates the property matching `propname` via
`gobject-set!`.

A convenient mechanism for creating a getter and a setter for a GObject
property.

```racket
prop:gobject : struct-type-property?
```

A structure type property that causes instances of a structure type to
work as GObject instances. The property value must be either a
`gi-instance` or a procedure that accepts the structure instance and
returns a `gi-instance`.

The `prop:gobject` property allows a GObject instance to be
transparently wrapped by a structure that may have additional values or
properties.

```racket
gobject<%> : interface?
```

A `gobject<%>` object encapsulates a gobject pointer. It looks for a
field called `pointer` and will use that as a value for `prop:gobject`,
so that objects implementing this interface return `#t` to `gobject?`
and `cpointer?`.


```racket
gobject% : class?    
  superclass: object%
  extends: gobject<%>
```

Instances of this class return `#t` to `gobject?`.

```racket
(new gobject% [pointer pointer]) -> (is-a?/c gobject%)
  pointer : gi-instance?                              
```


```racket
(make-gobject-delegate method-decl ...)
                                       
method-decl = id                       
            | (id internal-method)     
                                       
  internal-method : symbol?            
```

Create a `mixin` that defines a class extension that implements
`gobject<%>`. The specified `id`s will be defined as public methods that
delegate to the `pointer`. When `internal-method` is included, the
expression is assumed to result in a symbol that will be used to look up
the method in GIR. When no `internal-method` is provided, the method
name used by GIR will be the `id` with dashes replaced with underscores.

e.g.

`(make-gobject-delegate` `get-name` `get-factory` `[static-pad` `'get_static_pad])`

is equivalent to:

```racket
(mixin (gobject<%>) (gobject<%>)                       
  (super-new)                                          
  (inherit-field pointer)                              
  (define/public (get-name . args)                     
    (apply gobject-send pointer 'get_name args))       
  (define/public (get-factory . args)                  
    (apply gobject-send pointer 'get_factory args))    
  (define/public (static-pad . args)                   
    (apply gobject-send pointer 'get_static_pad args)))
```
