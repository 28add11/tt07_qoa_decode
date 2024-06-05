![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Tiny Tapeout 07 QOA Decoder

- [Read the documentation for project](docs/info.md)

## What is it?

This is an implementation of a hardware decoder for the [QOA audio format](https://qoaformat.org/). It is being manufactured with the [Tiny Tapeout](https://tinytapeout.com) project, and actual samples should be delivered in December!


## What next?

This has mostly been a learning project for me, so I could dive deeper into the architecture of how the chips that power almost everything nowadays work. This chip itself is not terribly good, with some odd code choices and naive decisions preformace wise, which is something I want to improve in the future. 

Going forward, I have a list of things I want to impove:
- **Improved SPI interface**. Currently it is very janky, and is the part of the chip I am most concerned about for actual functionality.
- **More paralell execution**. The SPI interface can read while the chip is executing, but I wish to improve the paralellism further by allowing the chip to execute multiple commands at once, such as sending a decoded sample at the same time as processing a new one. 
- **More advanced decode logic**. The current version of the chip decodes QOA files on a sample by sample basis, and cannot handle things like multi-channel audio by itself. This adds overhead to the controller chip, especially when it comes to RAM, which I hope to reduce.
- **Improved code quality**. I am very new to verilog and digital design, so just a general improvement of my code would likely help greatly.

## Tiny Tapeout resources

- [FAQ](https://tinytapeout.com/faq/)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
- [Learn how semiconductors work](https://tinytapeout.com/siliwiz/)
- [Join the community](https://tinytapeout.com/discord)
- [Build your design locally](https://docs.google.com/document/d/1aUUZ1jthRpg4QURIIyzlOaPWlmQzr-jBn3wZipVUPt4)
