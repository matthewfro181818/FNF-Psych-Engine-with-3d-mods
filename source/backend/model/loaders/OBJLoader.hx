package backend.model.loaders;

import backend.model.Model3D;

class OBJLoader
{
    public static function load(path:String):Model3D
    {
        var model = new Model3D();
        // Parse OBJ here (vertices, uvs, normals)
        return model;
    }
}
