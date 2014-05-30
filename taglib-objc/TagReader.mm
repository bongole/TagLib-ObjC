//
//  TagReader.m
//  TagLib-ObjC
//
//  Created by Me on 01/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TagReader.h"

#include <fileref.h>
#include "mpegfile.h"
#include "id3v2tag.h"
#include "id3v2frame.h"
#include "id3v2header.h"
#include "attachedpictureframe.h"
#include "mp4file.h"
#include "mp4tag.h"
#include "mp4coverart.h"

using namespace TagLib;

static inline NSString *NSStr(TagLib::String _string)
{
    if (_string.isNull() == false) {
        return [NSString stringWithUTF8String:_string.toCString(true)];
    } else {
        return nil;
    }
}
static inline TagLib::String TLStr(NSString *_string)
{
    return TagLib::String([_string UTF8String], TagLib::String::UTF8);
}

@interface TagReader ()
{
    FileRef _file;
}

@end

@implementation TagReader
@synthesize path=_path;

- (id)initWithFileAtPath:(NSString *)path
{
    if (self = [super init]) {
        [self loadFileAtPath:path];
    }
    return self;
}
- (id)init
{
    return [self initWithFileAtPath:nil];
}

- (void)loadFileAtPath:(NSString *)path
{
    _path = path;
    
    if (_path != nil) {
        _file = FileRef([path UTF8String]);
    } else {
        _file = FileRef();
    }
}

- (BOOL)save
{
    return (BOOL)_file.save();
}
- (BOOL)doubleSave
{
    return [self save] && [self save];
}

- (NSString *)title
{
    if (_file.tag())
    {
        return NSStr(_file.tag()->title());
    }
    else{
        return @"";
    }
    
}
- (void)setTitle:(NSString *)title
{
    _file.tag()->setTitle(TLStr(title));
}
- (NSString *)artist
{
    if (_file.tag())
    {
        return NSStr(_file.tag()->artist());
    }
    
    return @"";
    
}
- (void)setArtist:(NSString *)artist
{
    _file.tag()->setArtist(TLStr(artist));
}
- (NSString *)album
{
    if (_file.tag())
    {
        return NSStr(_file.tag()->album());
    }
    
    return @"";
}
- (void)setAlbum:(NSString *)album
{
    _file.tag()->setAlbum(TLStr(album));
}
- (NSNumber *)year
{
    if (_file.tag())
    {
        return [NSNumber numberWithUnsignedInt:_file.tag()->year()];
    }
    
    return [NSNumber numberWithUnsignedInt:2000];
}
- (void)setYear:(NSNumber *)year
{
    _file.tag()->setYear([year unsignedIntValue]);
}
- (NSString *)comment
{
    if (_file.tag())
    {
        return NSStr(_file.tag()->comment());
    }
    
    return @"";
}
- (void)setComment:(NSString *)comment
{
    _file.tag()->setComment(TLStr(comment));
}
- (NSNumber *)track
{
    return [NSNumber numberWithUnsignedInt:_file.tag()->track()];
}
- (void)setTrack:(NSNumber *)track
{
    _file.tag()->setTrack([track unsignedIntValue]);
}
- (NSString *)genre
{
    return NSStr(_file.tag()->genre());
}
- (void)setGenre:(NSString *)genre
{
    _file.tag()->setGenre(TLStr(genre));
}
- (NSData *)albumArt
{
    TagLib::File *f = _file.file();
    if( MPEG::File *file = dynamic_cast<MPEG::File *>(f) ){
        ID3v2::Tag *tag = file->ID3v2Tag();
        if (tag) {
            ID3v2::FrameList frameList = tag->frameListMap()["APIC"];
            ID3v2::AttachedPictureFrame *picture = NULL;
            
            if (!frameList.isEmpty() && NULL != (picture = dynamic_cast<ID3v2::AttachedPictureFrame *>(frameList.front()))) {
                TagLib::ByteVector bv = picture->picture();
                return [NSData dataWithBytes:bv.data() length:bv.size()];
            }
        }
    }
    else if( MP4::File *file = dynamic_cast<MP4::File *>(f) ){
        MP4::Tag *tag = file->tag();
        if( tag && tag->itemListMap().contains("covr") ){
            MP4::CoverArtList l = tag->itemListMap()["covr"].toCoverArtList();
            if( !l.isEmpty() ){
                MP4::CoverArt cover = l.front();
                TagLib::ByteVector bv = cover.data();
                return [NSData dataWithBytes:bv.data() length:bv.size()];
            }
        }
    }
    
    return nil;
}
- (void)setAlbumArt:(NSData *)albumArt
{
    TagLib::File *f = _file.file();
    if( MPEG::File *file = dynamic_cast<MPEG::File *>(f) ){
        ID3v2::Tag *tag = file->ID3v2Tag();
        if (tag) {
            tag->removeFrames("APIC");
            if (albumArt != nil && [albumArt length] > 0) {
                ID3v2::AttachedPictureFrame *picture = new ID3v2::AttachedPictureFrame();
                
                TagLib::ByteVector bv = ByteVector((const char *)[albumArt bytes], [albumArt length]);
                picture->setPicture(bv);
                picture->setMimeType(String("image/jpg"));
                picture->setType(ID3v2::AttachedPictureFrame::FrontCover);
                
                tag->addFrame(picture);
            }
        }
    }
    else if( MP4::File *file = dynamic_cast<MP4::File *>(f) ){
        MP4::Tag *tag = file->tag();
        if( tag ){
            MP4::CoverArtList l;
            TagLib::ByteVector bv = ByteVector((const char *)[albumArt bytes], [albumArt length]);
            l.append(MP4::CoverArt(MP4::CoverArt::JPEG, bv));
            tag->itemListMap()["covr"] = l;
        }
    }
}

- (NSData*)userData
{
    TagLib::File *f = _file.file();
    if( MP4::File *file = dynamic_cast<MP4::File *>(f) ){
        MP4::Tag *tag = file->tag();
        if( tag ){
            NSString *tagName = @"----:taglib:userdata";
            if( tag->itemListMap().contains([tagName UTF8String]) ){
                TagLib::ByteVectorList l = tag->itemListMap()[[tagName UTF8String]].toByteVectorList();
                TagLib::ByteVector bv = l.front();
                return [NSData dataWithBytes:bv.data() length:bv.size()];
            }
        }
        
    }
    
    return nil;
}

- (void)setUserData:(NSData *)data
{
     TagLib::File *f = _file.file();
    if( MP4::File *file = dynamic_cast<MP4::File *>(f) ){
        MP4::Tag *tag = file->tag();
        if( tag ){
            TagLib::ByteVectorList l;
            TagLib::ByteVector bv = ByteVector((const char *)[data bytes], [data length]);
            l.append(bv);
            
            NSString *tagName = @"----:taglib:userdata";
            tag->itemListMap()[[tagName UTF8String]] = l;
        }
    }
}

- (void)dealloc
{
    _path = nil;
}

@end
