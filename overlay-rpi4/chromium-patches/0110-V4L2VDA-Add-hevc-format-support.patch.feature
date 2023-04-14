From e86109fa5e05268acc3557d308e5ae12136b391a Mon Sep 17 00:00:00 2001
From: Hou Qi <qi.hou@nxp.com>
Date: Mon, 5 Sep 2022 10:38:53 +0800
Subject: [PATCH 10/17] V4L2VDA: Add hevc format support

Upstream-Status: Inappropriate [NXP specific]
---
 media/base/supported_types.cc                 |   2 +-
 media/gpu/v4l2/v4l2_device.cc                 |  28 ++++-
 media/gpu/v4l2/v4l2_vda_helpers.cc            | 119 ++++++++++++++++++
 media/gpu/v4l2/v4l2_vda_helpers.h             |  20 +++
 .../gpu/v4l2/v4l2_video_decode_accelerator.cc |   2 +-
 media/media_options.gni                       |   4 +-
 6 files changed, 170 insertions(+), 5 deletions(-)

Index: src/media/base/supported_types.cc
===================================================================
--- src.orig/media/base/supported_types.cc
+++ src/media/base/supported_types.cc
@@ -345,7 +345,7 @@ bool IsDefaultSupportedVideoType(const V
     case VideoCodec::kVP9:
       return IsVp9ProfileSupported(type);
     case VideoCodec::kHEVC:
-      return IsHevcProfileSupported(type);
+      return true;
     case VideoCodec::kMPEG4:
       return IsMPEG4Supported();
     case VideoCodec::kUnknown:
Index: src/media/gpu/v4l2/v4l2_device.cc
===================================================================
--- src.orig/media/gpu/v4l2/v4l2_device.cc
+++ src/media/gpu/v4l2/v4l2_device.cc
@@ -1587,7 +1587,9 @@ uint32_t V4L2Device::VideoCodecProfileTo
       return V4L2_PIX_FMT_VP9_FRAME;
     else
       return V4L2_PIX_FMT_VP9;
-  } else {
+  } else if (profile >= HEVCPROFILE_MIN && profile <= HEVCPROFILE_MAX) {
+    return V4L2_PIX_FMT_HEVC;
+  }else {
     DVLOGF(1) << "Unsupported profile: " << GetProfileName(profile);
     return 0;
   }
@@ -1631,6 +1633,16 @@ VideoCodecProfile V4L2ProfileToVideoCode
           return VP9PROFILE_PROFILE2;
       }
       break;
+    case VideoCodec::kHEVC:
+      switch (v4l2_profile) {
+        case V4L2_MPEG_VIDEO_HEVC_PROFILE_MAIN:
+          return HEVCPROFILE_MAIN;
+        case V4L2_MPEG_VIDEO_HEVC_PROFILE_MAIN_10:
+          return HEVCPROFILE_MAIN10;
+        case V4L2_MPEG_VIDEO_HEVC_PROFILE_MAIN_STILL_PICTURE:
+          return HEVCPROFILE_MAIN_STILL_PICTURE;
+      }
+      break;
     default:
       VLOGF(2) << "Unsupported codec: " << GetCodecName(codec);
   }
@@ -1656,6 +1668,9 @@ std::vector<VideoCodecProfile> V4L2Devic
       case VideoCodec::kVP9:
         query_id = V4L2_CID_MPEG_VIDEO_VP9_PROFILE;
         break;
+      case VideoCodec::kHEVC:
+        query_id = V4L2_CID_MPEG_VIDEO_HEVC_PROFILE;
+        break;
       default:
         return false;
     }
@@ -1708,6 +1723,17 @@ std::vector<VideoCodecProfile> V4L2Devic
         profiles = {VP9PROFILE_PROFILE0};
       }
       break;
+    case V4L2_PIX_FMT_HEVC:
+      if (!get_supported_profiles(VideoCodec::kHEVC, &profiles)) {
+        DLOG(WARNING) << "Driver doesn't support QUERY HEVC profiles, "
+                      << "use default values, main, mian-10, main-still-picture";
+        profiles = {
+            HEVCPROFILE_MAIN,
+            HEVCPROFILE_MAIN10,
+            HEVCPROFILE_MAIN_STILL_PICTURE,
+        };
+      }
+      break;
     default:
       VLOGF(1) << "Unhandled pixelformat " << FourccToString(pix_fmt);
       return {};
@@ -2025,7 +2051,7 @@ void V4L2Device::GetSupportedResolution(
     }
   }
   if (max_resolution->IsEmpty()) {
-    max_resolution->SetSize(1920, 1088);
+    max_resolution->SetSize(4096, 4096);
     VLOGF(1) << "GetSupportedResolution failed to get maximum resolution for "
              << "fourcc " << FourccToString(pixelformat) << ", fall back to "
              << max_resolution->ToString();
Index: src/media/gpu/v4l2/v4l2_vda_helpers.cc
===================================================================
--- src.orig/media/gpu/v4l2/v4l2_vda_helpers.cc
+++ src/media/gpu/v4l2/v4l2_vda_helpers.cc
@@ -14,6 +14,7 @@
 #include "media/gpu/v4l2/v4l2_device.h"
 #include "media/gpu/v4l2/v4l2_image_processor_backend.h"
 #include "media/video/h264_parser.h"
+#include "media/video/h265_parser.h"
 
 namespace media {
 namespace v4l2_vda_helpers {
@@ -153,6 +154,9 @@ InputBufferFragmentSplitter::CreateFromP
     case VideoCodec::kVP9:
       // VP8/VP9 don't need any frame splitting, use the default implementation.
       return std::make_unique<v4l2_vda_helpers::InputBufferFragmentSplitter>();
+    case VideoCodec::kHEVC:
+      return std::make_unique<
+	      v4l2_vda_helpers::H265InputBufferFragmentSplitter>();
     default:
       LOG(ERROR) << "Unhandled profile: " << profile;
       return nullptr;
@@ -272,5 +276,120 @@ bool H264InputBufferFragmentSplitter::Is
   return partial_frame_pending_;
 }
 
+H265InputBufferFragmentSplitter::H265InputBufferFragmentSplitter()
+    : h265_parser_(new H265Parser()) {}
+
+H265InputBufferFragmentSplitter::~H265InputBufferFragmentSplitter() = default;
+
+bool H265InputBufferFragmentSplitter::AdvanceFrameFragment(const uint8_t* data,
+                                                           size_t size,
+                                                           size_t* endpos) {
+  DCHECK(h265_parser_);
+
+  // For H265, we need to feed HW one frame at a time.  This is going to take
+  // some parsing of our input stream.
+  h265_parser_->SetStream(data, size);
+  H265NALU nalu;
+  H265Parser::Result result;
+  bool has_frame_data = false;
+  *endpos = 0;
+  DVLOGF(4) << "H265InputBufferFragmentSplitter::AdvanceFrameFragment size" << size;
+  // Keep on peeking the next NALs while they don't indicate a frame
+  // boundary.
+  while (true) {
+    bool end_of_frame = false;
+    result = h265_parser_->AdvanceToNextNALU(&nalu);
+    if (result == H265Parser::kInvalidStream ||
+        result == H265Parser::kUnsupportedStream) {
+      return false;
+    }
+
+    DVLOGF(4) << "NALU type " << nalu.nal_unit_type << "NALU size" << nalu.size;
+    if (result == H265Parser::kEOStream) {
+      // We've reached the end of the buffer before finding a frame boundary.
+      if (has_frame_data){
+	      //    partial_frame_pending_ = true;
+	      //    DVLOGF(4)<<"partial_frame_pending_ true as H265Parser::kEOStream has_frame_data";
+      }
+      *endpos = size;
+      DVLOGF(4)<<  " MET kEOStream  endpos " << *endpos <<" nalu.size " << nalu.size;
+      return true;
+    }
+    switch (nalu.nal_unit_type) {
+      case H265NALU::TRAIL_N:
+      case H265NALU::TRAIL_R:
+      case H265NALU::TSA_N:
+      case H265NALU::TSA_R:
+      case H265NALU::STSA_N:
+      case H265NALU::STSA_R:
+      case H265NALU::RADL_R:
+      case H265NALU::RADL_N:
+      case H265NALU::RASL_N:
+      case H265NALU::RASL_R:
+      case H265NALU::BLA_W_LP:
+      case H265NALU::BLA_W_RADL:
+      case H265NALU::BLA_N_LP:
+      case H265NALU::IDR_W_RADL:
+      case H265NALU::IDR_N_LP:
+      case H265NALU::CRA_NUT:
+        if (nalu.size < 1)
+          return false;
+
+        has_frame_data = true;
+
+        // For these two, if the "first_mb_in_slice" field is zero, start a
+        // new frame and return.  This field is Exp-Golomb coded starting on
+        // the eighth data bit of the NAL; a zero value is encoded with a
+        // leading '1' bit in the byte, which we can detect as the byte being
+        // (unsigned) greater than or equal to 0x80.
+        if (nalu.data[1] >= 0x80) {
+          end_of_frame = true;
+          break;
+        }
+        break;
+      case H265NALU::VPS_NUT:
+      case H265NALU::SPS_NUT:
+      case H265NALU::PPS_NUT:
+      case H265NALU::AUD_NUT:
+      case H265NALU::EOS_NUT:
+      case H265NALU::EOB_NUT:
+      case H265NALU::FD_NUT:
+      case H265NALU::PREFIX_SEI_NUT:
+      case H265NALU::SUFFIX_SEI_NUT:
+        // These unconditionally signal a frame boundary.
+        end_of_frame = true;
+        break;
+      default:
+        // For all others, keep going.
+        break;
+    }
+    if (end_of_frame) {
+      if (!partial_frame_pending_ && *endpos == 0) {
+        // The frame was previously restarted, and we haven't filled the
+        // current frame with any contents yet.  Start the new frame here and
+        // continue parsing NALs.
+      } else  {
+        // The frame wasn't previously restarted and/or we have contents for
+        // the current frame; signal the start of a new frame here: we don't
+        // have a partial frame anymore.
+        partial_frame_pending_ = false;
+      //  return true;
+      }
+    }
+    *endpos = (nalu.data + nalu.size) - data;
+  }
+  NOTREACHED();
+  return false;
+}
+
+void H265InputBufferFragmentSplitter::Reset() {
+  partial_frame_pending_ = false;
+  h265_parser_.reset(new H265Parser());
+}
+
+bool H265InputBufferFragmentSplitter::IsPartialFramePending() const {
+  return partial_frame_pending_;
+}
+
 }  // namespace v4l2_vda_helpers
 }  // namespace media
Index: src/media/gpu/v4l2/v4l2_vda_helpers.h
===================================================================
--- src.orig/media/gpu/v4l2/v4l2_vda_helpers.h
+++ src/media/gpu/v4l2/v4l2_vda_helpers.h
@@ -18,6 +18,7 @@ namespace media {
 
 class V4L2Device;
 class H264Parser;
+class H265Parser;
 
 // Helper static methods to be shared between V4L2VideoDecodeAccelerator and
 // V4L2SliceVideoDecodeAccelerator. This avoids some code duplication between
@@ -114,6 +115,25 @@ class H264InputBufferFragmentSplitter :
   // Set if we have a pending incomplete frame in the input buffer.
   bool partial_frame_pending_ = false;
 };
+
+class H265InputBufferFragmentSplitter : public InputBufferFragmentSplitter {
+ public:
+  explicit H265InputBufferFragmentSplitter();
+  ~H265InputBufferFragmentSplitter() override;
+
+  bool AdvanceFrameFragment(const uint8_t* data,
+                            size_t size,
+                            size_t* endpos) override;
+  void Reset() override;
+  bool IsPartialFramePending() const override;
+
+ private:
+  // For H264 decode, hardware requires that we send it frame-sized chunks.
+  // We'll need to parse the stream.
+  std::unique_ptr<H265Parser> h265_parser_;
+  // Set if we have a pending incomplete frame in the input buffer.
+  bool partial_frame_pending_ = false;
+};
 
 }  // namespace v4l2_vda_helpers
 }  // namespace media
Index: src/media/gpu/v4l2/v4l2_video_decode_accelerator.cc
===================================================================
--- src.orig/media/gpu/v4l2/v4l2_video_decode_accelerator.cc
+++ src/media/gpu/v4l2/v4l2_video_decode_accelerator.cc
@@ -87,7 +87,7 @@ bool IsVp9KSVCStream(uint32_t input_form
 
 // static
 const uint32_t V4L2VideoDecodeAccelerator::supported_input_fourccs_[] = {
-    V4L2_PIX_FMT_H264, V4L2_PIX_FMT_VP8, V4L2_PIX_FMT_VP9,
+    V4L2_PIX_FMT_H264, V4L2_PIX_FMT_VP8, V4L2_PIX_FMT_VP9, V4L2_PIX_FMT_HEVC,
 };
 
 // static
Index: src/media/media_options.gni
===================================================================
--- src.orig/media/media_options.gni
+++ src/media/media_options.gni
@@ -103,7 +103,7 @@ declare_args() {
   enable_hevc_parser_and_hw_decoder =
       proprietary_codecs &&
       (use_fuzzing_engine || use_chromeos_protected_media || is_win || is_mac ||
-       is_android || is_linux)
+       is_android || is_linux || is_chromeos)
 }
 
 # Use another declare_args() to allow dependence on
