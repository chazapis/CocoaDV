# CocoaDV

Cocoa Framework to manage DExtra connections to D-STAR ORF reflectors (e.g. [this fork](https://github.com/chazapis/xlxd) of [xlxd](https://github.com/LX3JL/xlxd)). Provides both macOS and iOS targets and is [Carthage](https://github.com/Carthage/Carthage) compatible.

CocoaDV implements the D-STAR [vocoder extension](https://github.com/chazapis/pydv#d-star-vocoder-extension) that allows the use of the open source codec [Codec 2](http://www.rowetel.com/codec2.html) with D-STAR, so it establishes a DExtra connection directly to the reflector without the need of an AMBE chip. If the reflector has the appropriate hardware, it will transcode and bridge communications with "traditional" D-STAR transceivers (and in some cases also DMR and System Fusion).

Estrella, the ORF reflector client for [macOS](https://github.com/chazapis/Estrella-macOS) and [iOS](https://github.com/chazapis/Estrella-iOS), uses CocoaDV.

---

CocoaDV uses the [CocoaCodec2](https://github.com/chazapis/CocoaCodec2) Cocoa Framework.

73 de SV9OAN
