/*
Copyright (c) 2018 Timur Gafarov

Boost Software License - Version 1.0 - August 17th, 2003
Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module dagon.resource.packageasset;

import std.stdio;
import std.string;
import std.format;

import dlib.core.memory;
import dlib.core.stream;
import dlib.filesystem.filesystem;
import dlib.filesystem.stdfs;
import dlib.container.array;
import dlib.container.dict;
import dagon.core.ownership;
import dagon.core.interfaces;
import dagon.resource.asset;
import dagon.resource.boxfs;
import dagon.resource.obj;
import dagon.graphics.mesh;
import dagon.graphics.texture;
import dagon.graphics.material;
import dagon.logics.entity;

class PackageAsset: Asset
{
    Dict!(OBJAsset, string) meshes;
    Dict!(Entity, string) entities;
    Dict!(Texture, string) textures;
    Dict!(Material, string) materials;
    
    BoxFileSystem boxfs;
    AssetManager assetManager;

    this(Owner o)
    {
        super(o);
        meshes = New!(Dict!(OBJAsset, string))();
        entities = New!(Dict!(Entity, string))();
        textures = New!(Dict!(Texture, string))();
        materials = New!(Dict!(Material, string))();
    }

    ~this()
    {
        release();
    }

    override bool loadThreadSafePart(string filename, InputStream istrm, ReadOnlyFileSystem fs, AssetManager mngr)
    {
        boxfs = New!BoxFileSystem(fs, filename);
        assetManager = mngr;
        return true;
    }

    override bool loadThreadUnsafePart()
    {
        return true;
    }
    
    bool loadAsset(Asset asset, string filename)
    {
        if (!fileExists(filename))
        {
            writefln("Error: cannot find file \"%s\" in package", filename);
            return false;
        }
        
        auto fstrm = boxfs.openForInput(filename);
        bool res = asset.loadThreadSafePart(filename, fstrm, boxfs, assetManager);
        asset.threadSafePartLoaded = res;
        Delete(fstrm);
        
        if (!res)
        {
            writefln("Error: failed to load asset \"%s\" from package", filename);
            return false;
        }
        else
        {
            res = asset.loadThreadUnsafePart();
            asset.threadUnsafePartLoaded = res;
            if (!res)
            {
                writefln("Error: failed to load asset \"%s\" from package", filename);
                return false;
            }
            else
            {
                return true;
            }
        }
    }
    
    Mesh mesh(string filename)
    {
        if (!(filename in meshes))
        {
            OBJAsset objAsset = New!OBJAsset(assetManager);
            if (loadAsset(objAsset, filename))
            {
                meshes[filename] = objAsset;
                return objAsset.mesh;
            }
            else
            {
                return null;
            }
        }
        else
        {
            return meshes[filename].mesh;
        }
    }
    
    Entity entity(string filename)
    {
        // TODO
        return null;
    }
    
    Texture texture(string filename)
    {
        // TODO
        return null;
    }
    
    Material material(string filename)
    {
        // TODO
        return null;
    }
    
    bool fileExists(string filename)
    {
        FileStat stat;
        return boxfs.stat(filename, stat);
    }

    override void release()
    {
        clearOwnedObjects();
        Delete(boxfs);
        Delete(meshes);
        Delete(entities);
        Delete(textures);
    }
}
