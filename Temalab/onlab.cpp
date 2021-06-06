// Temalab.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <iostream>
#define GLEW_STATIC
#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <fstream>
#include <string>
#include <sstream>
#include "vector.hh"

struct ShaderProgramSource
{
	std::string VertexSource;
	std::string FragmentSource;
};

static ShaderProgramSource ParseShader(const std::string& filepath)
{
	std::ifstream stream(filepath);
	std::string line;
	std::stringstream ss[2];
	int type = -1;
	while (getline(stream, line))
	{
		if (line.find("#shader") != std::string::npos)
		{
			if (line.find("vertex") != std::string::npos)
				type = 0;
			else if (line.find("fragment") != std::string::npos)
				type = 1;
		}
		else
		{
			ss[(int)type] << line << '\n';
		}
			
	}
	return { ss[0].str(), ss[1].str() };
}

static unsigned int CompileShader(unsigned int type, const std::string& source)
{
	unsigned int id = glCreateShader(type);
	const char* src = source.c_str();
	glShaderSource(id, 1, &src, nullptr);
	glCompileShader(id);

	int result;
	glGetShaderiv(id, GL_COMPILE_STATUS, &result);
	if (result == GL_FALSE) {
		int length;
		glGetShaderiv(id, GL_INFO_LOG_LENGTH, &length);
		char* message = (char*)alloca(length * sizeof(char));
		glGetShaderInfoLog(id, length, &length, message);
		std::cout << message << std::endl;
	}
	return id;
}

static int CreateShader(const std::string& vertexShader, const std::string& fragmentShader)
{
	unsigned int program = glCreateProgram();
	unsigned int vs = CompileShader(GL_VERTEX_SHADER, vertexShader);
	unsigned int fs = CompileShader(GL_FRAGMENT_SHADER, fragmentShader);
	glAttachShader(program, vs);
	glAttachShader(program, fs);
	glLinkProgram(program);
	glValidateProgram(program);
	return program;
}


Vector points[3][3][3];

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

Vector bezier(int n, int m, int l, Vector p) {
	Vector sumVector = Vector(0.0, 0.0, 0.0);
	float bx = 0;
	float by = 0;
	float bz = 0;

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
				else {
					sumVector.x += 2.0 * (points[i][j][k + 1].x - points[i][j][k].x) * bx * by * bz;
					sumVector.y += 2.0 * (points[i][j][k + 1].y - points[i][j][k].y) * bx * by * bz;
					sumVector.z += 2.0 * (points[i][j][k + 1].z - points[i][j][k].z) * bx * by * bz;
				}
			}
		}
	}
	return sumVector;
}

void freeForm(Vector p) {
	Vector v1 = bezier(1, 2, 2, p);
	Vector v2 = bezier(2, 1, 2, p);
	Vector v3 = bezier(2, 2, 1, p);

	std::cout << v1.x << " " << v1.y << " " << v1.z << std::endl;
	std::cout << v2.x << " " << v2.y << " " << v2.z << std::endl;
	std::cout << v3.x << " " << v3.y << " " << v3.z << std::endl;
	
}

int main()
{
	for (int i = 0; i <= 2; i++)
	{
		for (int j = 0; j <= 2; j++)
		{
			for (int k = 0; k <= 2; k++)
			{
				points[i][j][k] = Vector(i / 2.0, 1.0 +(j / 2.0), k / 2.0);
				if (j != 0) {
					points[i][j][k].y *= 2.0;
					points[i][j][k].y -= 1.0;
				}
				std::cout << points[i][j][k].x << " " << points[i][j][k].y << " " << points[i][j][k].z << std::endl;
			}
		}
	}
	
	freeForm(Vector(0.5,0.5,0.5));

	GLFWwindow* window;

	/* Initialize the library */
	if (!glfwInit())
		return -1;

	/* Create a windowed mode window and its OpenGL context */
	window = glfwCreateWindow(1000, 1000, "Sphere Tracing", NULL, NULL);
	if (!window)
	{
		glfwTerminate();
		return -1;
	}

	/* Make the window's context current */
	glfwMakeContextCurrent(window);

	glfwSwapInterval(1);
	if (glewInit() != GLEW_OK)
		std::cout << "Baj van";

	std::cout << glGetString(GL_VERSION) << std::endl;


	ShaderProgramSource source = ParseShader("Shader.shader");
	unsigned int shader = CreateShader(source.VertexSource, source.FragmentSource);
	glUseProgram(shader);
	int texcoord_index = glGetAttribLocation(shader, "uv");
	

	while (!glfwWindowShouldClose(window)) {
		glBegin(GL_QUADS);

			glVertexAttrib2f(texcoord_index, 1.0f, 0.0f); glVertex3f(1.0f, -1.0f, 0.0f);

			glVertexAttrib2f(texcoord_index, 1.0f, 1.0f); glVertex3f(1.0f, 1.0f, 0.0f);

			glVertexAttrib2f(texcoord_index, 0.0f, 1.0f); glVertex3f(-1.0f, 1.0f, 0.0f);

			glVertexAttrib2f(texcoord_index,0.0f, 0.0f);  glVertex3f(-1.0f, -1.0f, 0.0f);

		glEnd();
		glfwPollEvents();
		if (GLFW_PRESS == glfwGetKey(window, GLFW_KEY_ESCAPE)) {
			glfwSetWindowShouldClose(window, 1);
		}
		glfwSwapBuffers(window);
	}
	glfwTerminate();
	return 0;
}
