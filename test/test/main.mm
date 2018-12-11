#import <Cocoa/Cocoa.h>
#import <dlfcn.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcomma"
#pragma clang diagnostic ignored "-Wunused-function"

#define STB_IMAGE_IMPLEMENTATION
#define STBI_ONLY_PNG

namespace stb_image {    
    #import "stb_image.h"
}

#pragma clang diagnostic pop

typedef void hqxInit();
typedef void hq2x_32( uint32_t *src, uint32_t *dest, int width, int height );



int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSString *dylibPath = [[NSBundle mainBundle] pathForResource:@"libhqx" ofType:@"dylib"];
    
        void *libhqx = dlopen([dylibPath UTF8String],RTLD_LAZY);
        if(libhqx) {
            
            ((hqxInit *)dlsym(libhqx,"hqxInit"))();
            hq2x_32 *func = ((hq2x_32 *)dlsym(libhqx,"hq2x_32"));
            
            int w;
            int h;
            int bpp;
            
            // ABRG
            unsigned char *img = (unsigned char *)stb_image::stbi_load([[[NSBundle mainBundle] pathForResource:@"test" ofType:@"png"] UTF8String],&w,&h,&bpp,4);
            
            
            if(bpp==4) {
                
                unsigned int *dst = new unsigned int[w*2*h*2];
                
                unsigned int *ptr = (unsigned int *)img;
                
                // ABGR to ARGB
                for(int k=0; k<w*h; k++) {
                    
                    unsigned int tmp = ptr[k];
                    
                    unsigned char r = (tmp)&0xFF;
                    unsigned char b = (tmp>>16)&0xFF;
                    
                    ptr[k] = (tmp&0xFF00FF00)|(r<<16)|(b);
                    
                }
                
                // ARGB
                func((unsigned int *)img,dst,w,h);
                
                NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                    initWithBitmapDataPlanes:NULL
                    pixelsWide:w*2
                    pixelsHigh:h*2
                    bitsPerSample:8
                    samplesPerPixel:4
                    hasAlpha:YES
                    isPlanar:NO
                    colorSpaceName:NSDeviceRGBColorSpace
                    bitmapFormat:NSBitmapFormatAlphaFirst
                    bytesPerRow:(w*2)<<2
                    bitsPerPixel:0
                ];
                
                unsigned int *bmp = (unsigned int *)[rep bitmapData];
                
                // ARGB to BGRA
                unsigned int *p = (unsigned int *)dst;
                for(int k=0; k<w*2*h*2; k++) {
                    unsigned int tmp = *p++;
                    unsigned char r = (tmp>>16)&0xFF;
                    unsigned char g = (tmp>>8)&0xFF;
                    unsigned char b = tmp&0xFF;
                    
                    // BGRA
                    bmp[k] = 0x000000FF|b<<24|g<<16|r<<8;
                }
                
                [[NSPasteboard generalPasteboard] clearContents];
                [[NSPasteboard generalPasteboard] setData:[rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}] forType:NSPasteboardTypePNG];
                
                delete[] dst;
                
                NSLog(@"done");
                
            }
            else {
                NSLog(@"error: bpp != 4");
            }
            
            delete[] img;
            
        }
        else {
            NSLog(@"error: not found libhqx.dylib");
        }
        
    }
}
