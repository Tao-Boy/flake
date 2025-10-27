self: super: {
      google-chrome = super.google-chrome.override {
        commandLineArgs = "--enable-features=AcceleratedVideoDecodeLinuxGL,VaapiVideoEncoder,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo";
      };
}