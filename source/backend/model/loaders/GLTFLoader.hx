package backend.model.loaders;

class GLTFLoader
{
    public static function load(path:String):Model3D
    {
        // Parse JSON
        // Load buffers
        // Create meshes
        // Load skins + animations if present
        return new SkinnedModel3D();
    }
}
