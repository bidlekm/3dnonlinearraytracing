#shader vertex
#version 430 core

layout(location = 0) in vec3 position;
in vec2 uv;
out vec2 UV;

void main()
{
	gl_Position = vec4(position,1.0);
    UV = uv;
}





#shader fragment
#version 430 core

layout(location = 0) out vec4 color;
in vec2 UV;

const float PI = 3.1415926535897932384626433832795f;
const float fzconst = 0.30f;
vec3 points[3][3][3];

int fact(int n) {
    int sum = 1;
    for (int i = 1; i <= n; ++i) {
        sum = sum * i;
    }
    return sum;
}

float get_b(int d, int i, float t) {
    float combination = fact(d) / (fact(i) * fact(d - i));
    return (combination * pow(1 - t, d - i) * pow(t, i));
}

vec3 bezier(int n, int m, int l, vec3 p) {
    vec3 sumVector = vec3(0.0, 0.0, 0.0);
    float bx = 0.0;
    float by = 0.0;
    float bz = 0.0;

    for (int i = 0; i <= n; ++i)
    {
        for (int j = 0; j <= m; ++j)
        {
            for (int k = 0; k <= l; ++k)
            {
                bx = get_b(n, i, p.x);
                by = get_b(m, j, p.y);
                bz = get_b(l, k, p.z);
                    if (n == 1) {
                        sumVector.x += 2.0 * (points[i + 1][j][k].x - points[i][j][k].x) * bx * by * bz;
                        sumVector.y += 2.0 * (points[i + 1][j][k].y - points[i][j][k].y) * bx * by * bz;
                        sumVector.z += 2.0 * (points[i + 1][j][k].z - points[i][j][k].z) * bx * by * bz;
                    }
                    else if (m == 1) {
                        sumVector.x += 2.0 * (points[i][j + 1][k].x - points[i][j][k].x) * bx * by * bz;
                        sumVector.y += 2.0 * (points[i][j + 1][k].y - points[i][j][k].y) * bx * by * bz;
                        sumVector.z += 2.0 * (points[i][j + 1][k].z - points[i][j][k].z) * bx * by * bz;
                    }
                    else if (l == 1 ){
                        sumVector.x += 2.0 * (points[i][j][k + 1].x - points[i][j][k].x) * bx * by * bz;
                        sumVector.y += 2.0 * (points[i][j][k + 1].y - points[i][j][k].y) * bx * by * bz;
                        sumVector.z += 2.0 * (points[i][j][k + 1].z - points[i][j][k].z) * bx * by * bz;
                    }
            }
        }
    }
    return sumVector;
}

mat3 freeForm(vec3 p) {
    mat3 matrix;
    matrix[0] = bezier(1, 2, 2, p);
    matrix[1] = bezier(2, 1, 2, p);
    matrix[2] = bezier(2, 2, 1, p);
    return matrix;
}


//f(z) = p.z* 0.7f
mat3 csavaras(vec3 p, in float angle) {
    return mat3(cos(angle), -sin(angle), -p.x * sin(angle) * fzconst - p.y * cos(angle) * fzconst,
        sin(angle), cos(angle), p.x * cos(angle) * fzconst - p.y * sin(angle) * fzconst,
        0, 0, 1);
}

float distance_from_sphere(vec3 p, vec3 c, float r)
{
    return length(p - c) - r;
}

float distance_from_plane(vec3 n, vec3 p) {

    n = normalize(n);
    return dot(n, p - vec3(0,-2.0,0));
}

float distance_from_torus(vec3 p, vec3 c, vec2 t)
{   
    
    vec2 q = vec2(length(c.xz-p.xz) - t.x, c.y-p.y);
    return length(q) - t.y;
}

float distance_from_octahedron(vec3 p, vec3 c, float s)
{   
    p = abs(p-c);
    return (p.x + p.y + p.z - s) * 0.57735027;
}

mat3 rotationX(in float angle) {
    return mat3(1.0f, 0, 0, 
                0, cos(angle), -sin(angle), 
                0, sin(angle), cos(angle));
}

mat3 rotationY(in float angle) {
    return mat3(cos(angle), 0, sin(angle),
                0, 1.0f, 0,
                -sin(angle), 0, cos(angle));
}

mat3 rotationZ(in float angle) {
    return mat3(cos(angle), -sin(angle), 0, 
                sin(angle), cos(angle), 0, 
                0, 0, 1);
}

mat3 rotation(in vec3 angles) {
    mat3 rotX = rotationX(angles.x);
    mat3 rotY = rotationY(angles.y);
    mat3 rotZ = rotationZ(angles.z);
    return rotX * rotY * rotZ;
}


float map_the_world(in vec3 p)
{
    float objects[4];


    float scale = 2.0f;
    vec3 rotationAngles = vec3(PI / 3.0f, 0.5f, PI / 4.0f * 3.0f);
    vec3 displacement = vec3(0.0f, 0.0f, 0.0f);


    vec3 fromObjectSpace = p - displacement;
    mat3 rotationMatrix = rotation(rotationAngles);

    rotationMatrix = transpose(rotationMatrix); // Orthonormal matrix ---> A^T*A = I

    fromObjectSpace = fromObjectSpace * rotationMatrix; // apply inverse rotation R^-1 
    fromObjectSpace *= 1 / scale; //apply scaling
    vec3 csavaras = p * inverse(csavaras(p, p.z * fzconst));
    vec3 freeform;


    //TODO: sugár metszi-e?
    //bounding volume hierarchy
    /*if (p.x > 0.0 && p.x < 1.0 && p.y > 0.0 && p.y < 2.0 && p.z > 0.0 && p.z < 1.0)
        freeform = p *inverse(freeForm(vec3(p.x, p.y/2.0, p.z)));
    else
        freeform = p ;*/
    

    objects[0] = distance_from_sphere(p, vec3(0.5, 0.5, 0.5), 0.45);
    objects[1] = distance_from_plane(vec3(0, 1, 0), p);
    objects[2] = distance_from_torus(csavaras, vec3(0, 0.0, 0), vec2(1.5, 0.1));// *scale;
    objects[3] = distance_from_octahedron(p, vec3(2.5, 0.5, 0), 1);

    float minDist = objects[0];
    for (int i = 0; i < 4; ++i)
    {
        if (objects[i] < minDist)
            minDist = objects[i];
    }
    //return objects[0];
    //float distortion = sin(3.0 * p.x) * sin(3.0 * p.y) * sin(3.0 * p.z) * 0.15;
    return minDist;// +distortion;
}

vec3 calculate_normal(in vec3 p)
{
    float delta = 0.001f;
    float gradient_x = map_the_world(p + vec3(delta, 0, 0)) - map_the_world(p + vec3(-delta, 0, 0));
    float gradient_y = map_the_world(p + vec3(0, delta, 0)) - map_the_world(p + vec3(0, -delta, 0));
    float gradient_z = map_the_world(p + vec3(0, 0, delta)) - map_the_world(p + vec3(0, 0, -delta));
    return normalize(vec3(gradient_x, gradient_y, gradient_z));
}

bool sphereTraceShadow(vec3 rayOrigin, vec3 rayDirection, float maxDistance)
{
    float threshold = 0.15f;
    float t = 0;
    while (t < maxDistance) {      
        float minDistance = 10.0f;
        vec3 from = rayOrigin + t * rayDirection;
        if (map_the_world(from) < minDistance)
        {
            minDistance = map_the_world(from);
            minDistance += threshold;
            if (minDistance < threshold * t)
                return true;
        }
        // no intersection, move along the ray by minDistance
        t += minDistance;
    }
    return false;
}



vec3 shade(vec3 rayOrigin, vec3 rayDirection, float t)
{
    vec3 p = rayOrigin + t * rayDirection;
    vec3 n = calculate_normal(p);
    vec3 R = vec3(0.0f, 0.0f, 0.0f);

    vec3 lightDir = vec3(2.0, 5.0, 0.0) - p;
    if (dot(n, lightDir) >  0.0f) {
        float dist = length(vec3(2.0, 5.0, -3.0) - p);
        lightDir = normalize(lightDir);
        bool shadow = sphereTraceShadow(p, lightDir, dist);
        if (shadow)
            R += dot(n, lightDir) * vec3(1.0f, 0.0f, 0.0f) * 0.5f ;
    }

    return R;
}


vec3 ray_march(in vec3 ro, in vec3 rd)
{
    float total_distance_traveled = 0.0;

    for (int i = 0; i < 1512; ++i)
    {

        //vec3 csavaras = p * inverse(csavaras(p, p.z * fzconst));
        vec3 current_position = ro +total_distance_traveled * rd;
        //current_position += total_distance_traveled *rd * inverse(csavaras(current_position, current_position.z * fzconst));

        float distance_to_closest = map_the_world(current_position);

        if (distance_to_closest < 0.01f)
        {
            vec3 normal = calculate_normal(current_position);
            vec3 light_position = vec3(2.0, 5.0, -3.0);
            vec3 direction_to_light = normalize( light_position - current_position);
            float diffuse_intensity = max(0.2, dot(normal, direction_to_light));
            vec3 shadeing = shade(ro, rd, total_distance_traveled);
            //return normal * 0.5 + 0.5;
            //return vec3(1.0, 0.0, 0.0) * diffuse_intensity - shadeing;
            return vec3(1.0, 0.0, 0.0) * diffuse_intensity;
        }
        if (total_distance_traveled > 100.0)
        {
            break;
        }
        total_distance_traveled += distance_to_closest;
    }
    return vec3(1.0);
}




void main()
{
   
    for (int i = 0; i <= 2; i++)
    {
        for (int j = 0; j <= 2; j++)
        {
            for (int k = 0; k <= 2; k++)
            {
                points[i][j][k] = vec3(i / 2.0, j / 2.0, k / 2.0);
                if (j != 0) {
                    points[i][j][k].y *= 2.0;
                    
                }
            }
        }
    }
    points[2][1][0].x = 0.75;
    points[2][1][1].x = 0.75;
    points[2][1][2].x = 0.75;
    vec2 vuv = UV * 2.0f - 1.0f;
    vec3 camera_position = vec3(0.0, 1.0, -5.0);
    vec3 ro = camera_position;
    vec3 rd = vec3(vuv, 1.0);
    vec3 shaded_color = ray_march(ro, rd);
	color = vec4(shaded_color, 1.0);
}