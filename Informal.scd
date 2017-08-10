
// These are informal manual testing methods that were not converted
// to formal unit tests. They should be, if it proves necessary for
// reliability.

// Saving and loading mapped mode SpaceTracker
(fork{
  // Test fromMapped
  s.bootSync;
  b=Buffer.allocMapped(s, 5, 5, [2,3,4]);
  s.sync;
  b.do {|c, i|
    c[0].setn(0, [
      1, 60+i, 0.5, 0, 0, 0,
      1, 70+i, 0.5, 1500, 1500, 1500,
      1, 80+i, 0.5, 3000, 3000, 3000
    ]);
    c[1..].pairsDo {|ch, b|
      b.setn(0, Array.series(5000).normalize);
    };
  };
  s.sync;

  //SpaceTracker.bufferTo("/tmp/sc/foo.note", b.collect{|b|b[0]}, 3);
  
  SpaceTracker.fromMapped("/tmp/sc/foo.note", b, 3);
  s.sync;
  c=SpaceTracker.toMapped(s, "/tmp/sc/foo.note");
})

c=SpaceTracker.toMapped(s, "/tmp/sc/foo.note");
SpaceTracker.fromMapped("/tmp/sc/foo.note", b, 30);
c
c[1][0].getn(0,30){|m|m.postln}
b[2][0].getn(0,30){|m|m.postln}
b.collect{|b|b[0].set(0,0.1)}

// Testing Continuous Playback
(
  z.free;
  z={
    var controls=PlayBufM.kr(5, b);
    controls.poll;
    Out.kr(0,0);
  }.play;
)

// Testing regular SpaceTracker
d=b.collect{|x|x[0]};

d=SpaceTracker.alloc(s, 4)

SpaceTracker.fromBuffer("/tmp/sc/bar.note", SpaceTracker.alloc(s,4), 30);

SpaceTracker("/tmp/sc/bar.note").fromBuffer(d,30);

// Testing mapped mode recording and playback more isolatedly
(fork{
  n.free;
  n={PlayBufM.kr(5,b)[0][4].poll}.play; 
})

(fork{
  s.bootSync;
  n.free;
  n={PlayBufS.kr(5,z).poll}.play; 
})
(fork{
  s.bootSync;
  MIDIIn.connectAll;
  z.free;
  z=SpaceTracker.alloc(s, 5, 5);
})

z[0].getn(0,30){|m|m.postln};

// Test record
(fork{
  o.free;
  o={
    var c;
    c = ShapedControl.kr(\voice, 5, 5);
    RecordBufS.kr(c, z);
  }.play; 
  m.free;
  m=ShapedMIDIC(o,[1,2,3,4,5],[\bend, 74, \touch]);
})

// Test record (using JackMidi with QuNeo)
(fork{
  s.bootSync;
  z.free;
  z=SpaceTracker.alloc(s, 5, 5);
  o.free;
  o={
    var c;
    c = JackMIDIIn.kr(1, notes:Array.series(5,36), controls:Array.series(15,23).clump(3).collect{|x|`x},polytouch:false);
    RecordBufT.kr(c, z);
  }.play; 
  {PlayBufT.kr(5,z).poll}.play
})


(
  u.free;
  u={
    PlayBuf.kr(1, b[1][6], 1, 1, 8.4).poll;
  }.play;
)


// Testing the max number for a continuosuly rising phasor (part of RecordBufM)
(
o.free;
o={
  Phasor.kr(1,1,0,2147483647).poll;
}.play;
)

b[0][0].getn(0,30){|m|m.postln};

// Main mapped mode testing; save and load, record, playback, and a nice sound
// for playing the Linnstrument on, the main reason to introduce mapped mode.

SpaceTracker.fromMapped("/tmp/sc/foo.note", b, 30);
SpaceTracker.fromMapped("/tmp/sc/foo.note", c, 30);
(fork{
  Server.internal;
  s.bootSync;
  MIDIIn.connectAll;
  b.free;
  b=Buffer.allocMapped(s, 5, 5, [2,3,4]);
  c.free;
  c=SpaceTracker.toMapped(s, "/tmp/sc/foo.note");
  s.sync;

  d = SpaceTracker.alloc(s, 5, 5);
  
  e = SpaceTracker.toBuffer(s, "/tmp/sc/bar.note");
  
  f = SpaceTracker.toBuffer(s, "/tmp/sc/test.note");

  s.sync;
  \done.postln;
})



(
  x.free;
  x={
    var controls, voice, frames;

    controls = StControl.kr(\voice, 5, 5);
    frames = RecordBufM.kr(controls, b);
    //controls = PlayBufM.kr(5, b);
    //controls = PlayBufM.kr(5, c);
    //frames = RecordBufS.kr(controls, b.collect{|b|b[0]});
    //frames.poll;
    //controls = PlayBufS.kr(5, b.collect{|b|b[0]});

    //RecordBufS.kr(controls.collect{|c|c[0..1]}, d);
    //controls = PlayBufS.kr(5, e);

    //controls.poll;

    voice=controls.collect {|d|
      var freq, voice, n,v,b,bb,t,l, r;
      #n,v,b,t,l = d;
      
      r = Lag.kr(n>0 * (b > 200), 0.001);
      
      n=if(n>0,n,48);
      
      bb=b;

      bb = bb/ 16392;

      bb=bb.max(0.4).min(0.65);
      bb = bb - 0.4 * 4;

      b = b/8196;

      l = if(l==0,v,l);

      t=t/128;
      l=l/128;
      v=v/128;

      l=l*l;

      t=t*0.875 + 0.125;
      l=l*0.9999 + 0.0001;
      
      freq = n.midicps;//*b;
      freq=freq.max(30);

      //t=LagUD.kr(t, 0.005, 0.01);
      //l=LagUD.kr(l, 0.005, 0.01);
      //b=LagUD.kr(b, 0.005, 0.01);
      
      //voice=Pulse.ar(freq, t, l)*0.25*r;
      //voice = SinOsc.ar(freq, 0)+SinOsc.ar(freq*2,0,t)*0.125;

      voice = Saw.ar(freq, 0.5);
      voice = RLPF.ar(voice, 2000 * t*2, 1-(0.9*(bb))) * l;
      voice=voice*0.1*r;
    }.sum;
    voice = voice + JPverb.ar(voice);
  }.play(addAction:\addToTail);
  m.free;
  m=ShapedMIDIC(x,[1,2,3,4,5],[\bend, 74, \touch]);
)

z.free;
z.free;z={PlayBufM.kr(5, b).poll}.play;
z.free;z={PlayBufM.kr(5, c).poll}.play;

// Testing BufSet, a UGen to set the buffer sample rate
// (this is normally only possible when reading a file),
// see https://github.com/supercollider/supercollider/issues/1952

(fork{
  s.bootSync;
  b = Buffer.alloc(s, 128);
  s.sync;
  x.free;
  x={
    BufSet.kr(b, \trig.tr, \samplerate.kr);
  }.play;
})
x.set(\trig, 1, \samplerate, 48000.rand);
(
y.free;
y={
  BufSampleRate.kr(b).poll(1);
}.play;
)
b.updateInfo;
b.sampleRate;
b.write("/tmp/a.wav");

c=Buffer.read(s, "/tmp/b.wav");
c.sampleRate;
c.write("/tmp/c.wav");

// Testing DetectEndS, this is for removing
// the need to specify an array to SpaceTracker.bufferTo
// specifying how many frames were recorded

(fork {
  s.bootSync;
  b = Buffer.alloc(s, 128, 5);
  s.sync;
  x.free;
  x={
    DetectEndS.kr(b).poll(1);
  }.play;
})
b.set(0, 0);

// Testing a one-sample synth for relaying
// DetectEndS information back to the language
// as part of the SpaceTracker.bufferTo process
(fork {
  s.bootSync;
  r.free;
  r=OSCFunc({ 'foo'.postln }, '/foo');
  x.free;
  x={|t_trig|
    SendReply.kr(DC.kr(1), '/foo', 1);
    FreeSelf.kr(Impulse.kr);
  }.play;
  \bar.postln;
  s.sync;
  \buz.postln;
})

// Testing toBuffer without specifying frames

(fork {
  s.bootSync;
  b = SpaceTracker.alloc(s,5,5,128);
  s.sync;
  b.do {|b| b.set(0, 1, 1, 60)};
  s.sync;
  SpaceTracker.bufferTo("/tmp/foo.note", b);
})



// Testing with the QuNeo and JackMIDIIn:record
(fork{
  s.bootSync;
  "jack_connect \"`jack_lsp | grep midi | grep out | grep -v Through`\" JackMIDIUGens:midi_in".systemCmd;
  m.free;
  m=Buffer.allocMapped(s,5,5,[2,3,4]);
  x.free;
  x={
    var c;
    c=JackMIDIIn.kr(1, notes:Array.series(5,36), controls:Array.series(15,23).clump(3).collect{|x|`x},polytouch:false);
    
    RecordBufM.kr(c, m);
    
    c.collect{|c|
      var n,v,p,x,y;
      #n,v,p,x,y=c;
      RLPF.ar(Saw.ar(Latch.kr(n,n).midicps,(p/128).lag),y/128*350+100,x/128*0.25+0.125)*4;
    }.sum!2;


  }.play;
})

"rm -rf /tmp/foo".systemCmd; m.writeMapped("/tmp/foo");
m.writeMapped("/tmp/foo");
(fork {
  s.sync;
  m.do {|m|
    m[0].writeTimed("/tmp/a.aiff","aiff","float");
    s.sync;
    g=SoundFile.openRead("/tmp/a.aiff");
    g.toCSV("/tmp/a.csv");
    g.close;
    "cat /tmp/a.csv | head".unixCmdGetStdOut.postln;
  };
})

s.boot;
b=Buffer.allocTimed(s, 1, 1);
b=Buffer.alloc(s,128);
b.set(0,1,1,1,2,1,3,1);
b.writeTimed("/tmp/a.aif") 
b.numFrames

//m[1][2].getn(0,1000,{|a|a.pairsDo{|a,b,i| if (a==0) {i.postln;}  }})


//playback
(fork{
  s.bootSync;
  //m.free;m=SpaceTracker.toMapped(s,"/tmp/foo");s.sync;
  m.free;m=Buffer.readMapped(s,"/tmp/foo");s.sync;
})

m.do{|m|m[1..].pairsDo{|a,b|b.numFrames.postln}};
m.postln;
(fork{
  x.free;
  x={
    var c;
    c=PlayBufM.kr(5,m).poll;
    c.collect{|c|
      var n,v,p,x,y;
      #n,v,p,x,y=c;
//      p=x=y=(n>0)*64;
      RLPF.ar(Saw.ar(Latch.kr(n,n).midicps,(p/128).lag),y/128*350+100,x/128*0.25+0.125)*4;
    }.sum!2;
  }.play;
})

m[1][6].numFrames

(fork{
s.bootSync;
w=SoundFile("/tmp/foo.aiff");
w.headerFormat="aiff";
w.sampleFormat="float";
w.openWrite;
w.writeData(FloatArray[1,2,3,4,5]);
w.close;
b=Buffer.readTimed(s, w.path);
})

Buffer.readTimed(s, "/tmp/m606717946.aiff");

//playback without mapped
(fork{
  s.bootSync;
  n = m.collect{|b|b[0]};
  x.free;
  x={
    var c;
    c=PlayBufT.kr(5,n).collect{|c| c[0..1]++(c[0]>0*64!3) }.poll; // dummy controls
    c.collect{|c|
      var n,v,p,x,y;
      #n,v,p,x,y=c;
      RLPF.ar(Saw.ar(Latch.kr(n,n).midicps,(p/128).lag),y/128*350+100,x/128*0.25+0.125)*4;
    }.sum;
  }.play;
})


// Verify PlayBufT for empty buffers
(fork {
  s.bootSync;
  b=Buffer.alloc(s, 128,2);
  {
    PlayBufT.kr(1,b,1,0,1).poll;
  }.play
})

2**31-1

(2**32) 

(
  var path="/tmp/foo", channels=[2,3,4];
  File.use(path+/+"meta", "w") {|f|
    f.write(channels.join(" "));
  };
)

// Test read

(fork {
  s.bootSync;
  b = Buffer.allocTimed(s);
  s.sync;
  b.sendCollection([1,32,0.5,33,1,34]);
  s.sync;
  b.getn(0,6,{|c|c.postln});
  s.sync;
  x.free;
  x={
    BufFramesT.kr(b, 1, 0, 0, 2).poll; 
  }.play;
  b.writeTimed("/tmp/a.aiff", "aiff", 0, 0);
  s.sync;
  g=SoundFile.openRead("/tmp/a.aiff");
  g.toCSV("/tmp/a.csv");
  g.close;
  "cat /tmp/a.csv | head".unixCmdGetStdOut.postln;
})

// Test write

(fork {
  s.bootSync;
  b=Buffer.readTimed(s, "/tmp/a.aiff", 0.75, 1);
  s.sync;
  s.sync;
  s.sync;
  b.getn(0,6,{|c|c.postln})
})





(
TestBufFramesT.run;

UnitTest.runTest("TestBufFramesT:test_shavecenter");

UnitTest.runTest("TestBufFramesT:test_prepost");

UnitTest.runTest("TestBufFramesT:test_pre_onlast");
UnitTest.runTest("TestBufFramesT:test_pre_onsecondlast");

UnitTest.runTest("TestBufFramesT:test_multichannel_long");


)

(
(10+20).rand.collect{[10.0.rand,127.rand,127.rand,127.rand]}.flat.asCompileString;
)

(
a=[ 9.1337192058563, 17, 20, 97, 6.399017572403, 37, 101, 92, 4.0919506549835, 71, 69, 97, 4.0838253498077, 27, 6, 114, 8.4694528579712, 37, 47, 3, 0.12431740760803, 91, 69, 25, 8.5956215858459, 1, 2, 33, 1.5181195735931, 90, 18, 96, 5.3417408466339, 95, 101, 22, 5.9933578968048, 64, 58, 43, 6.6469585895538, 49, 120, 56, 9.3143355846405, 50, 81, 117, 2.033303976059, 118, 1, 35, 1.2936115264893, 118, 11, 102, 6.7575621604919, 27, 63, 124, 4.3031942844391, 113, 44, 88, 4.9205708503723, 19, 102, 4, 5.390852689743, 53, 20, 14, 9.8089456558228, 81, 94, 25, 4.6411645412445, 80, 83, 107, 2.2814118862152, 15, 92, 80, 2.0842516422272, 45, 82, 90, 7.6886701583862, 67, 87, 60, 9.4486975669861, 15, 74, 87, 5.8108699321747, 98, 99, 119, 3.7641739845276, 112, 38, 48 ];

a.unlace(4).first.sum

)
